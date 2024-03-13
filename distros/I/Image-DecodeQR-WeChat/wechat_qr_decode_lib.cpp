/*
our $VERSION = '2.1';
*/

/* Here we have C++ code which calls OpenCV functions related
   to decoding QR codes, reading and writing images etc.
   This code must live in its own file, totally independent of
   XS code. In this way we keep the namespaces happy and avoid
   clashes with Perl's macros and OpenCV functions/macros.
   This is a good practice when interfacing Perl with external
   C/C++ libraries: keep the interface outside of the XS by
   creating intermediate functions.
   In XS call the intermediate functions.
*/

#include <iostream>
#include <fstream>
#include <chrono>
#include <opencv2/opencv.hpp>
#include <opencv2/wechat_qrcode.hpp>

#if HAS_HIGHGUI == 1
#include <opencv2/highgui.hpp>
#endif

#include <string.h>

/* for getopt */
#include <stdio.h>
#include <unistd.h>

#include "wechat_qr_decode_lib.hpp"

using namespace std;
using namespace cv;
using namespace std::chrono;

void display(Mat &im, Mat &bbox);
int save_image_with_framed_qrcodes_and_metadata(
	std::string &outbase,
	Mat &im,
	Mat bbox,
	std::string text,
	int verbosity
);

/* Find all QR codes in the input image and return
   back an array of text payloads after decoding them
   or NULL on failure.
   In case of success, payloads_sz is set to the size of
   the returned payloads array (zero size is possible).
   Parameters:
    infilename : is the input image (jpeg, png etc),
    outbasename : is optional, if specified it will create a copy
	of the input file with all QR codes highlighted in green
    modelsdir : 4 model files are required and this is the dir they reside
	models are from opencv-4.5.5/build/downloads/wechat_qrcode
    verbosity : set it to > 0 to get verbose output and debug messages
    graphicaldisplayresult : set it to 1 to display a window with the QR code found
    payloads_sz : pointer to contain the number of QR codes successfully decoded from the image.
*/
int wechat_qr_decode(
	char *infilename,
	char *modelsdir,
	char *outbasename, // optional, can be NULL
	int verbosity,
	int graphicaldisplayresult,
	int dumpqrimagestofile,
	// we return these back to caller if !NULL we allocate and caller needs to free
	char ***_payloads,
	// this assumes that each bbox has 4 coordinates, each with 2 items = 8 items, the num of bboxes is the payloads_sz
	float ***_bboxes,
	// this is the size of both bboxes and payloads
	size_t *payloads_sz
){
	if( payloads_sz != NULL ) *payloads_sz = 0;
	else if( (_payloads != NULL) || (_bboxes != NULL) ){ fprintf(stderr, "wechat_qr_decode() : error, you specified to returned payloads and/or bboxes (you supplied pointers) but supplied payloads_sz is NULL, you need to supply also a valid pointer for returning back their size.\n"); return 1; }
	char **payloads = NULL;
	float **bboxes = NULL;

	int i, j;
	if( infilename == NULL ){ fprintf(stderr, "wechat_qr_decode() : error, an input image file must be specified (-i).\n"); return 1; }
	if( modelsdir == NULL ){ fprintf(stderr, "wechat_qr_decode() : error, the directory with the models (detect.prototxt, detect.caffemodel, sr.prototxt, sr.caffemodel) must be specified (-m).\n"); return 1; }

	if( verbosity > 0 ){ fprintf(stdout, "wechat_qr_decode() : called for image '%s' ...\n", infilename); }

	// Instantiate WeChat QR Code detector.
	// These model files must exist and can be found in opencv src dir under downloads/wechat_qrcode
	// if one is not found then exception is thrown!
	Ptr<wechat_qrcode::WeChatQRCode> detector;
	std::string Modelsdir(modelsdir);
	std::vector<std::string> models = {
		Modelsdir+std::string("/detect.prototxt"),
		Modelsdir+std::string("/detect.caffemodel"),
		Modelsdir+std::string("/sr.prototxt"),
		Modelsdir+std::string("/sr.caffemodel")
	};
	// check if all model files exist
	for(std::string m : models){
		if( verbosity > 0 ){ fprintf(stdout, "wechat_qr_decode() : checking model '%s' ... ", m.c_str()); }
		if( access( m.c_str(), F_OK ) == -1 ){
			if( verbosity > 0 ){ fprintf(stdout, "failed.\n"); }
			fprintf(stderr, "wechat_qr_decode() : error, model '%s' does not exist!\n", m.c_str());
			return 1;
		}
		if( verbosity > 0 ){ fprintf(stdout, "success.\n"); }
	}

	try {
		detector = makePtr<wechat_qrcode::WeChatQRCode>(models[0], models[1], models[2], models[3]);
	} catch(Exception ex){
		std::cerr << "Exception caught: " << ex.what() << std::endl;
		std::cerr << "I have checked that the models exist and are accessible but do make sure:" << std::endl;
		for(std::string m : models){ std::cerr << "  '" << m << "'." << std::endl; }
		return 1;
	}
	if( verbosity > 0 ){ fprintf(stdout, "wechat_qr_decode() : created detector successfully.\n"); }

	if( verbosity > 0 ){ fprintf(stdout, "wechat_qr_decode() : reading input image '%s' ...\n", infilename); }
	// Read image from command line input or the default.
	Mat img = imread(infilename);
	if( img.empty() ){ fprintf(stderr, "wechat_qr_decode() : error, call to imread has failed for input image '%s'.\n", infilename); return 1; }

	// Declare vector 'points' to store bounding box coordinates.
	vector<Mat> points;
	// Start time.
	auto start = high_resolution_clock::now();
	// Detect and decode.
	if( verbosity > 0 ){ fprintf(stdout, "wechat_qr_decode() : starting detection ...\n"); }
	vector<std::string> res = detector->detectAndDecode(img, points);
	// End time.
	auto stop = high_resolution_clock::now();
	// Time taken in milliseconds.
	auto duration = duration_cast<milliseconds>(stop - start);
	if( verbosity > 0 ){ std::cout << "wechat_qr_decode() : done in " << duration.count() << " mseconds. Found " << res.size() << " code(s)." << std::endl; }

	if( res.size() != points.size() ){ fprintf(stderr, "wechat_qr_decode() : error, number of results (payloads, %zu) is not the same as the number of bounding-boxes (%zu).\n", res.size(), points.size()); return 1; }
	bool have_outfile = false;
	// If detected.
	if (res.size() > 0){
		int cdi;
		fstream outfh;
		if( outbasename != NULL ){
			std::string outfilename(outbasename);
			outfilename += ".xml";
			outfh.open(outfilename, ios::out);
			if( ! outfh ){
				fprintf(stderr, "wechat_qr_decode() : error opening output file '%s', I will use stdout : %s\n", outfilename, strerror(errno));
				have_outfile = false;
			} else have_outfile = true;
		}
		if( _payloads != NULL ){
			if( (*_payloads=payloads=(char **)malloc(res.size()*sizeof(char *))) == NULL ){ fprintf(stderr, "wechat_qr_decode() : error, failed to allocate %zu bytes for returned payloads.\n", res.size()*sizeof(char *)); return 1; }
			if( verbosity > 0 ){ fprintf(stdout, "wechat_qr_decode() : allocated %zu payload(s) for returning back results ...\n", res.size()); }
		}
		if( _bboxes != NULL ){
			if( (*_bboxes=bboxes=(float **)malloc(res.size()*sizeof(float *))) == NULL ){ fprintf(stderr, "wechat_qr_decode() : error, failed to allocate %zu bytes for returned bboxes.\n", res.size()*sizeof(float *)); return 1; }
			if( verbosity > 0 ){ fprintf(stdout, "wechat_qr_decode() : allocated %zu bbox(es) for returning back results ...\n", res.size()); }
		}
		if( have_outfile ){
			outfh << "<qrcodes>\n";
		}
		for(i=0;i<res.size();i++){
			std::string value = res[i];
			if( verbosity > 0 ){ fprintf(stdout, "wechat_qr_decode() : detected code %d/%d : %s\n", i+1, res.size(), value.c_str()); }
			if( *_payloads != NULL ){
				// allocate for the payload plus terminating \0
				if( (payloads[i]=(char *)malloc((value.length()+1)*sizeof(char))) == NULL ){ fprintf(stderr, "wechat_qr_decode() : error, failed to allocate %zu bytes for payload %d/%d (%s).\n", (value.length()+1)*sizeof(char), i+1, res.size(), value.c_str()); return 1; }
				if( verbosity > 0 ){ fprintf(stdout, "wechat_qr_decode() : allocated %zu bytes for %d/%d payload (length: %zu): '%s'.\n", (value.length()+1)*sizeof(char), i+1, res.size(), value.length(), value.c_str()); }
				strcpy(payloads[i], value.c_str());
				if( verbosity > 0 ){ fprintf(stdout, "wechat_qr_decode() : copied payload %d/%d into results (%s).\n", i+1, res.size(), payloads[i]); }
			}
			if( *_bboxes != NULL ){
				// allocate 8 floats for each bbox
				if( (bboxes[i]=(float *)malloc(8*sizeof(float))) == NULL ){ fprintf(stderr, "wechat_qr_decode() : error, failed to allocate %zu bytes for bbox %d/%d: ", 8*sizeof(float), i+1, res.size()); std::cerr << points[i] << std::endl; return 1; }
				if( verbosity > 0 ){ fprintf(stdout, "wechat_qr_decode() : allocated %zu bytes for %d/%d bbox (length: %zu): ", 8*sizeof(float), i+1, res.size()); std::cout << points[i] << std::endl; }
				for(j=0;j<8;j++) bboxes[i][j] = points[i].at<float>(j);
				if( verbosity > 0 ){ fprintf(stdout, "wechat_qr_decode() : copied bbox %d/%d into results: ", i+1, res.size()); std::cout << points[i] << std::endl; }
			}
			// print them payloads to file if we have one
			if( have_outfile ){
				outfh << "  <qrcode>\n    <payload>" << value << "</payload>\n    <boundingbox>";
				for(j=0;j<8;j+=2){
					outfh << "[" << bboxes[i][j] << ", " << bboxes[i][j+1] << "]";
					if( j < 5 ){ outfh << ", "; }
				};
				outfh << "</boundingbox>\n  </qrcode>\n";
			} else {
				std::cout  << value << std::endl;
			}
			if( verbosity > 0 ){ std::cout << "wechat_qr_decode() : these are the bounding boxes for above payload:" << points[i] << std::endl; }
		}

		if( have_outfile ){
			outfh << "</qrcodes>\n"; 
			outfh.close();
		}
		if( payloads_sz != NULL ) *payloads_sz = (size_t )(res.size());

		if( (dumpqrimagestofile > 0) && (outbasename!=NULL) ){
			std::string ob(outbasename);
			ob += ".";
			for(i=0;i<res.size();i++){
				std::string ob(outbasename);
				ob.append(".").append(std::to_string(i));
				cv::Mat newimg = img.clone();
				if( save_image_with_framed_qrcodes_and_metadata(
					ob, newimg, points[i], res[i], verbosity)
				){ fprintf(stderr, "wechat_qr_decode() : error, call to save_image_with_framed_qrcodes_and_metadata() has failed for this output basename '%s'. Ignoring and continue ...\n", outbasename); }
			}
		}

		if( graphicaldisplayresult > 0 ){
			if( opencv_has_highgui() ==  0 ){
				fprintf(stderr, "wechat_qr_decode() : there's no highgui support for current OpenCV installation, graphical presentation  of results is not possible.\n");
			} else {
				if( verbosity > 0 ){ fprintf(stdout, "wechat_qr_decode() : displaying detected images to window (mileage may vary especially if running through shell) ...\n"); }
				// Iterate through the vector and convert to Mat. Required,
				// as we need to access the elements while drawing the box.
				for(i=0;i<res.size();i++){
					Mat img2 = img.clone();
					Mat1f matBbox;
					for(j=0;j<points[i].size().height;j++){
						matBbox.push_back(points[i].row(j));
					}
					std::cout << "Time taken : "  << duration.count() <<
					    " milliseconds" << std::endl;
					std::cout << matBbox << std::endl;
					// Display bounding box. 
					display(img2, matBbox);
				}
			}
		}
	} else {
		// if( res.size() > 0 ...
		fprintf(stderr, "wechat_qr_decode() : no QR code was found in image '%s' or failed to detect one.\n", infilename);
		return 0; // success but no qr-codes detected, nothing has been allocated, payloads_sz is 0
	}
	if( verbosity > 0 ){ fprintf(stdout, "wechat_qr_decode() : done, returning %zu payload(s) and bbox(es) (memory location: %p, %p).\n", *payloads_sz, payloads); }

	return 0; // success
}

int save_image_with_framed_qrcodes_and_metadata(
	std::string &outbase,
	Mat &im,
	Mat bbox,
	std::string text,
	int verbosity
){
	int n = bbox.rows;
	for(int i=0;i<n;i++){
		line(im, Point2i(
				bbox.at<float>(i,0),
				bbox.at<float>(i,1)
			 ), 
			 Point2i(
				bbox.at<float>((i+1)%n,0), 
				bbox.at<float>((i+1)%n,1)
			),
			Scalar(0,255,0),
			3
		);
	}
	std::string bboxstr("<boundingbox>");
	for(int i=0;i<n;i++){
		bboxstr.append("[")
			.append(std::to_string(bbox.at<float>(i,0)))
			.append(", ")
			.append(std::to_string(bbox.at<float>(i,1)))
			.append("], ")
		;
	}
	bboxstr = bboxstr.substr(0, bboxstr.size()-2);

	std::string outfile(outbase);
	outfile += ".jpg";
	if( ! imwrite(outfile, im) ){ fprintf(stderr, "save_image_with_framed_qrcodes_and_metadata() : failed to save image to '%s'.\n", outbase.c_str()); return 1; }
	if( verbosity > 0 ){ fprintf(stdout, "save_image_with_framed_qrcodes_and_metadata() : saved qr-code area to image '%s'.\n", outfile.c_str()); }

	std::string outfile2(outbase);
	outfile2 += ".xml";
	fstream outfh;
	outfh.open(outfile2, ios::out);
	if( ! outfh ){ fprintf(stderr, "save_image_with_framed_qrcodes_and_metadata() : error opening output file '%s', for writing detected qr-code metadata: %s\n", outfile2, strerror(errno)); return 1; }
	outfh << "<qrcode>\n  <payload>" << text << "</payload>\n  <boundingbox>" << bboxstr << "</boundingbox>\n</qrcode>\n";
	outfh.close();
	if( verbosity > 0 ){ fprintf(stdout, "save_image_with_framed_qrcodes_and_metadata() : saved qr-code metadata as text to file '%s'.\n", outfile.c_str()); }
	return 0;
}

void display(Mat &im, Mat &bbox){
#if HAS_HIGHGUI == 1
	int n = bbox.rows;
	for(int i = 0; i < n; i++)
	{
	      line(im, Point2i(bbox.at<float>(i,0), bbox.at<float>(i,1)), 
		     Point2i( bbox.at<float>((i+1) % n,0), 
		 bbox.at<float>((i+1) % n,1)), Scalar(0,255,0), 3);
	}
	imshow("Image", im);
	std::cout << "display() : press a key to continue ..." << std::endl;
	waitKey(0);
#else
	fprintf(stderr, "display() : opencv was not compiled with highgui, can not display images. No worries, just save them to file.\n");
#endif
}

/* Exactly as wechat_qr_decode(), above, but with C linkage
   so as to avoid name mangling of C++
   Use this when it complains that it can not
   find *decode() symbol
   The difference is in the hpp file which declares the C linkage
*/
int wechat_qr_decode_with_C_linkage(
	char *infilename,
	char *modelsdir,
	char *outbasename, // optional, can be NULL
	int verbosity,
	int graphicaldisplayresult,
	int dumpqrimagestofile,
	// we return these back to caller if !NULL we allocate and caller needs to free
	char ***_payloads,
	// this assumes that each bbox has 8 items, the num of bboxes is the payloads_sz
	float ***_bboxes,
	// this is the size of both bboxes and payloads
	size_t *payloads_sz
){
	return wechat_qr_decode(
		infilename,
		modelsdir,
		outbasename,
		verbosity,
		graphicaldisplayresult,
		dumpqrimagestofile,
		_payloads,
		_bboxes,
		payloads_sz
	);
}

int opencv_has_highgui(void){
#if HAS_HIGHGUI == 0
        return(0);
#else
        return(1);
#endif
}

int opencv_has_highgui_with_C_linkage(void){
	return opencv_has_highgui();
}

