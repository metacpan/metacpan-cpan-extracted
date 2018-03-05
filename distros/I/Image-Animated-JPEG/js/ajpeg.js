//------------------------------------
//
// Enable browsers to play AJPEG files
//
//------------------------------------

'use strict';

var debug = false;

window.onload = ajpeg;

var img; // global, we work on one <img> tag at a time
var frame_blobs = [];

function ajpeg() {
	if (debug) console.log('ajpeg onload');

	var images = document.getElementsByTagName('img');

	for(var i = 0; i < images.length; i++){
		// console.log(images[i]);

		if( ! images[i].src.match(/\.ajpeg$/) ){
			continue;
		}

		if (debug) console.log(images[i].src + ' is an AJPEG image (by suffix)');

		var url = images[i].src;
		img = images[i];

		img.id = i;

		// smallest possible placeholder, https://github.com/mathiasbynens/small
		// img.src="data:image/jpeg;base64,/9j/2wBDAAMCAgICAgMCAgIDAwMDBAYEBAQEBAgGBgUGCQgKCgkICQkKDA8MCgsOCwkJDRENDg8QEBEQCgwSExIQEw8QEBD/yQALCAABAAEBAREA/8wABgAQEAX/2gAIAQEAAD8A0s8g/9k=";
		// images[i].src="data:image/gif;base64,R0lGODlhAQABAAAAADs=";
		// browser displayable:
		// images[i].src="data:image/gif;base64,R0lGODdhAQABAIAAAP///////ywAAAAAAQABAAACAkQBADs=";


		var xhr = getXMLHttpRequest();
		if (debug) console.log(xhr, images[i]);
		xhr.onreadystatechange = function() { ProcessResponse(xhr) };
		xhr.open("GET", url, true);
	//	xhr.overrideMimeType('text/plain; charset=x-user-defined'); // workaround for binary data https://developer.mozilla.org/de/docs/Web/API/XMLHttpRequest/Using_XMLHttpRequest
		xhr.responseType = "arraybuffer";
		if (debug) console.log('GET '+ url);

		xhr.send(null);
	//	console.log(xhr.response);
	}
}

function getXMLHttpRequest() {
	var xhr = null;

	if (window.XMLHttpRequest || window.ActiveXObject) {
		if (window.ActiveXObject) {
			try {
				xhr = new ActiveXObject("Msxml2.XMLHTTP");
			} catch(e) {
				xhr = new ActiveXObject("Microsoft.XMLHTTP");
			}
		} else {
			xhr = new XMLHttpRequest();
		}
	} else {
		alert("Your browser does not support XMLHTTP");
		return null;
	}

	return xhr;
}

function ProcessResponse(xhr) {
	if(xhr.readyState==4){
		if(xhr.status==200){
			if (debug) console.log('xhr ok ');

		//	var img = document.getElementById("1");

		//	if (debug) console.log( encode64(xhr.responseText) );

		//	img.src="data:image/jpeg;base64," + encode64(xhr.responseText);
		//	img.src="data:image/jpeg;base64," + window.btoa(xhr.response); // .response as we use xhr.responseType = "arraybuffer";

			var blob = new Blob([xhr.response]);

			if (debug) console.log(img, blob);

			var fileReader = new FileReader();
			fileReader.onload = function(e) {
				if (debug) console.log('handle binary file');
				handleBinaryFile(e.target.result, blob);
			};
			if (debug) console.log('read as array buffer');
			fileReader.readAsArrayBuffer(blob);

		//	var test_frame = blob.slice( 389, 1027, {type: "image/jpeg"});
		}else{
			if (debug) console.log('xhr error');
		}
	}else{
	//	if (debug) console.log('xhr readystate '+ xhr.readyState);
	}
}

function handleBinaryFile(binFile, blob) {
	if (debug) console.log(' handling', blob);
	var indx = indexer(binFile);
	if (debug) console.log("index done", indx);

	if(indx.length > 1){
		for(var i = 0; i < indx.length; i++){
			var len = indx[i+1] ? indx[i+1].offset : blob.size;

			if (debug) console.log("blob.slice", indx[i].offset, len);
			frame_blobs.push( blob.slice( indx[i].offset, len, {type: "image/jpeg"}) );
		}

		if (debug) console.log("frame_blobs", frame_blobs);

		var reader = new FileReader();
		reader.onload = function(event){
			// parser(event.target.result, indx); // send buffer
			parserAJPEG(event.target.result, indx); // send buffer
		};
		reader.readAsArrayBuffer(frame_blobs[0]); // testing: todo: read all frame headers, cmp. hard-coded indx[0].delay below, for example

		on_timer(indx);
	}
}

/* actual marker parsing abandoned, as the AJPEG marker is recognisable enough to find it without decoding everything
function parser(buffer, indx) {
	if (debug) console.log("parse: ");

        var dataView = new DataView(buffer);

        var offset = 2;
	var len = indx[1].offset;
	if (debug) console.log("parse: len: ", len);

	while (offset < len) {
		var marker = dataView.getUint8(offset);
		console.log(" parse: offset: ", offset);

		if (marker == 0xFF) {	// munge FFs (JPEG markers can be padded with unlimited 0xFF's)
		    console.log("FF marker");
		    for (;;) {
			offset++;
			marker = dataView.getUint8(offset);
			    console.log("marker", marker);
			if(marker != 0xFF){
				break;
			}
		    }
		}

		if( marker == 0xDA || marker == 0xD9){
			console.log("SOS/EOI marker");
			break ;  // exit once we reach a SOS marker, or EOI (end of image)
		}

		var marker_len = dataView.getUint16(offset, false); // big-endian short http://stackoverflow.com/questions/7869752/javascript-typed-arrays-and-endianness
		if(marker_len < 2){ // data-less marker
			break;
		}
		offset += 2;
		console.log(" marker_length: ", marker_len);

		if( marker < 0xE0){ // data-less marker
			break;
		}

		if(marker == 0xE0){
		    console.log("APP0 marker");
		}

		offset++;
	}

}
*/

function parserAJPEG(buffer, indx) {
	if (debug) console.log("parseAJPEG: ");

        var dataView = new DataView(buffer);

        var offset = 2;
	var len = indx[1].offset;
	if (debug) console.log("parse: len: ", len);


        var isAjpegMarker = function(dataView, offset){
            return (
                dataView.getUint8(offset) === 0x41 &&
                dataView.getUint8(offset+1) === 0x4A &&
                dataView.getUint8(offset+2) === 0x50 &&
                dataView.getUint8(offset+3) === 0x45 &&
                dataView.getUint8(offset+4) === 0x47 &&
                dataView.getUint8(offset+5) === 0x00
            );
        };

	while (offset < len) {
		if( isAjpegMarker(dataView, offset) ){
			if (debug) console.log("APP0: AJPEG marker at", offset);

			var marker_len = dataView.getUint16(offset-2, false); // big-endian short http://stackoverflow.com/questions/7869752/javascript-typed-arrays-and-endianness
			if (debug) console.log(" marker_length: ", marker_len);

			for(var i = 1; i < marker_len; i++){
				if(i < 6){
					if (debug) console.log("skip");
					continue;
				}

				var byte = dataView.getUint8(offset + i);

				if(i == 6){
					if (debug) console.log("AJPEG version", byte);
					continue;
				}

				if(byte ==  0x01){
					i++;
					var value = dataView.getUint8(offset + i);
					if (debug) console.log(" delay:", value);
					indx[0].delay = value;
				}else if(byte ==  0x02){
					i++;
					var value = dataView.getUint16(offset + i, false);
					i++;
					if (debug) console.log(" delay2:", value);
					indx[0].delay = value;
				}else if(byte ==  0x04){
					i++;
					var value = dataView.getUint32(offset + i, false);
					i = i + 3;
					if (debug) console.log(" delay4:", value);
					indx[0].delay = value;
				}else if(byte ==  0x11){
					i++;
					var value = dataView.getUint32(offset + i, false);
					if (debug) console.log(" repeat:", value);
					indx[0].repeat = value;
				}else if(byte ==  0x12){
					i++;
					var value = dataView.getUint32(offset + i, false);
					i++;
					if (debug) console.log(" repeat2:", value);
					indx[0].repeat = value;
				}
			}
		}
		offset++;
	}

}

var index_pointer;
function index_next() {
	if(index_pointer >= frame_blobs.length - 1){
		index_pointer = 0;
		if (debug) console.log("index rewound to ", index_pointer);
	}else{
		index_pointer++;
		if (debug) console.log("index forward to ", index_pointer);
	}
}

var reader = new FileReader();
reader.onload = function(event){
	// if (debug) console.log( event.target.result ); //event.target.results contains the base64 code to create the image.
	img.src = event.target.result;
};

var active;
var delay = 100; // AJPEG default 100ms
function on_timer(indx) {
	clearInterval(active);

	var frame_index = index_pointer;
	if (debug) console.log("display frame", frame_index);

	// reading/converting the blob over and over from base64 to image data is inefficient, right?
	// todo;: replace this with attaching "new Image()" objects to the dom, referencing them by a
	// (local) URI of some sort and exchanging them programmatically, instead of this here
	reader.readAsDataURL(frame_blobs[frame_index]); // trigger Convert the blob from binary to base64

	if(indx[frame_index].delay){
		delay = indx[frame_index].delay;

		if(delay < 10){ // hard delay (fps) floor
			delay = 10;
		}
	}

	index_next();

	active = window.setInterval(function(){ on_timer(indx); }, delay);
	if (debug) console.log('timer installed', delay);
}

function indexer(file) {
        var dataView = new DataView(file);

	if (debug) console.log("indexer:", dataView);

        if (debug) console.log("Got file of length " + file.byteLength);
        if ((dataView.getUint8(0) == 0xFF) && (dataView.getUint8(1) == 0xD8)) {
		if (debug) console.log("Found start-markers for valid JPEG");
	}else{
		if (debug) console.log("Not a valid JPEG");
		return false; // not a valid jpeg
        }

	var frames = [];
	index_pointer = 0;

	frames.push({
		offset: 0
	});

        var offset = 2,
            length = file.byteLength,
            marker;

	var cnt = 1;
	while (offset < length) {
		marker = dataView.getUint8(offset);

		//  if (debug) console.log("offset:", offset, "marker:", marker);

		// if (debug) console.log(marker);

		if (marker == 0xd8) {
			if (debug) console.log("offset", offset, "marker 0xD8");

			if ( (dataView.getUint8(offset - 1) == 0xFF) && (dataView.getUint8(offset - 2) == 0xD9)) {
				// if (debug) console.log(" and it's a boundary to next frame");
				if (debug) console.log("found next frame");

				frames.push({
					offset: offset-1 // remember: we looked for "D8", but frame starts with "FF D8"
				});

				// if (debug) console.log(offset, frames[cnt - 1].offset);
				// frames[cnt - 1].len = offset - frames[cnt - 1].offset;
				cnt++;
			}
		}

		offset += 1;
	}

	return frames;
}
