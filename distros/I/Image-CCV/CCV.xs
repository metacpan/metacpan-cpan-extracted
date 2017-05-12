/* libpng v1.2 insists of loading setjmp.h itself and provides no
   configuration to tell it that all will be OK :-((
   
   Inline::C does not provide a way to unshift the #include either :-(((
*/
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "INLINE_CCV.h"
#include "ccv-src/lib/ccv.h"

ccv_sift_param_t* myccv_pack_parameters(int noctaves, int nlevels, int up2x, int edge_threshold, int norm_threshold, int peak_threshold)
{
	ccv_sift_param_t* res;
	res = malloc(sizeof(*res));
	
	res->noctaves = noctaves;
	res->nlevels = nlevels;
	res->up2x = up2x;
	res->edge_threshold = edge_threshold;
	res->norm_threshold = norm_threshold;
	res->peak_threshold = peak_threshold;
	
	return res;
}

/* Should this just become a tiearray interface?! */
void myccv_keypoints_to_list(ccv_array_t* keypoints)
{
      Inline_Stack_Vars;
      Inline_Stack_Reset;

      AV* res = newAV();
      int i;
      for (i = 0; i < keypoints->rnum; i++) {
          ccv_keypoint_t* kp = (ccv_keypoint_t*)ccv_array_get(keypoints, i);
          AV* point = newAV();
          
          av_push( point, newSVnv( kp->x ));
          av_push( point, newSVnv( kp->y ));
      };
      
      Inline_Stack_Push(sv_2mortal(newRV_noinc((SV*) res)));
      Inline_Stack_Done;
      return;
}

void myccv_get_descriptor(char* file, ccv_sift_param_t* param)
{
	Inline_Stack_Vars;
	Inline_Stack_Reset;

	ccv_dense_matrix_t* data = 0;
	ccv_read(file, &data, CCV_IO_GRAY | CCV_IO_ANY_FILE);
	assert(data);
	
	ccv_array_t* keypoints = 0;
	ccv_dense_matrix_t* descriptor = 0;
	ccv_sift(data, &keypoints, &descriptor, 0, *param);

	/* TODO We should blesss those into proper classes for automatic deallocation */
        Inline_Stack_Push(sv_2mortal(newSVpv((void *)descriptor,0)));
	Inline_Stack_Push(sv_2mortal(newSVpv((void *)keypoints,0)));
	
	Inline_Stack_Done;
	return;
}

void myccv_sift(char* object_file, char* scene_file, ccv_sift_param_t* param)
{
        Inline_Stack_Vars;
        Inline_Stack_Reset;

	ccv_enable_default_cache();
	ccv_dense_matrix_t* object = 0;
	ccv_dense_matrix_t* image = 0;
	ccv_read(object_file, &object, CCV_IO_GRAY | CCV_IO_ANY_FILE);
	assert(object);
	ccv_read(scene_file, &image, CCV_IO_GRAY | CCV_IO_ANY_FILE);
	assert(image);
	ccv_array_t* obj_keypoints = 0;
	ccv_dense_matrix_t* obj_desc = 0;
	ccv_sift(object, &obj_keypoints, &obj_desc, 0, *param);
	ccv_array_t* image_keypoints = 0;
	ccv_dense_matrix_t* image_desc = 0;
	ccv_sift(image, &image_keypoints, &image_desc, 0, *param);
	int i, j, k;
	int match = 0;
	for (i = 0; i < obj_keypoints->rnum; i++)
	{
		float* odesc = obj_desc->data.f32 + i * 128;
		int minj = -1;
		double mind = 1e6, mind2 = 1e6;
		for (j = 0; j < image_keypoints->rnum; j++)
		{
			float* idesc = image_desc->data.f32 + j * 128;
			double d = 0;
			for (k = 0; k < 128; k++)
			{
				d += (odesc[k] - idesc[k]) * (odesc[k] - idesc[k]);
				if (d > mind2)
					break;
			}
			if (d < mind)
			{
				mind2 = mind;
				mind = d;
				minj = j;
			} else if (d < mind2) {
				mind2 = d;
			}
		}
		if (mind < mind2 * 0.36)
		{
			ccv_keypoint_t* op = (ccv_keypoint_t*)ccv_array_get(obj_keypoints, i);
			ccv_keypoint_t* kp = (ccv_keypoint_t*)ccv_array_get(image_keypoints, minj);
			// Create the new 4-item array
			AV* res = newAV();
			av_push( res, newSVnv( op->x ));
			av_push( res, newSVnv( op->y ));
			av_push( res, newSVnv( kp->x ));
			av_push( res, newSVnv( kp->y ));
                        Inline_Stack_Push(sv_2mortal(newRV_noinc((SV*) res)));
			match++;
		}
	}
	ccv_array_free(obj_keypoints);
	ccv_array_free(image_keypoints);
	ccv_matrix_free(obj_desc);
	ccv_matrix_free(image_desc);
	ccv_matrix_free(object);
	ccv_matrix_free(image);
	ccv_disable_cache();
	Inline_Stack_Done;
	return;
}
// 3

MODULE = Image::CCV	PACKAGE = Image::CCV	

PROTOTYPES: DISABLE


void
myccv_detect_faces (filename, training_data)
	char *	filename
	char *	training_data
	PREINIT:
	I32* temp;
	PPCODE:
	temp = PL_markstack_ptr++;
	Inline_Stack_Vars;
	Inline_Stack_Reset;
	int i;
	ccv_enable_default_cache();
	ccv_dense_matrix_t* image = 0;
	/* TODO: Make the cascade accessible from the outside */
	ccv_bbf_classifier_cascade_t* cascade = ccv_bbf_read_classifier_cascade(training_data);
	ccv_read(filename, &image, CCV_IO_GRAY | CCV_IO_ANY_FILE);
	if (image != 0)
	{
		/* TODO: Make the BBF parameters accessible from the outside */
		ccv_bbf_param_t params = { .interval = 5, .min_neighbors = 2, .accurate = 1, .flags = 0, .size = ccv_size(24, 24) };
		ccv_array_t* seq = ccv_bbf_detect_objects(image, &cascade, 1, params);
		for (i = 0; i < seq->rnum; i++)
		{
			ccv_comp_t* comp = (ccv_comp_t*)ccv_array_get(seq, i);
			/* Create the new 5-item array */
			AV* res = newAV();
			av_push( res, newSVnv( comp->rect.x ));
			av_push( res, newSVnv( comp->rect.y ));
			av_push( res, newSVnv( comp->rect.width ));
			av_push( res, newSVnv( comp->rect.height ));
			av_push( res, newSVnv( comp->confidence ));
                        Inline_Stack_Push(sv_2mortal(newRV_noinc((SV*) res)));
		}
		ccv_array_free(seq);
		ccv_matrix_free(image);
	}
	ccv_bbf_classifier_cascade_free(cascade);
	ccv_disable_cache();
	Inline_Stack_Done;
	if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
	  PL_markstack_ptr = temp;
	  XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
	return; /* assume stack size is correct */

ccv_sift_param_t *
myccv_pack_parameters (noctaves, nlevels, up2x, edge_threshold, norm_threshold, peak_threshold)
	int	noctaves
	int	nlevels
	int	up2x
	int	edge_threshold
	int	norm_threshold
	int	peak_threshold

void
myccv_keypoints_to_list (keypoints)
	ccv_array_t *	keypoints
	PREINIT:
	I32* temp;
	PPCODE:
	temp = PL_markstack_ptr++;
	myccv_keypoints_to_list(keypoints);
	if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
	  PL_markstack_ptr = temp;
	  XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
	return; /* assume stack size is correct */

void
myccv_get_descriptor (file, param)
	char *	file
	ccv_sift_param_t *	param
	PREINIT:
	I32* temp;
	PPCODE:
	temp = PL_markstack_ptr++;
	myccv_get_descriptor(file, param);
	if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
	  PL_markstack_ptr = temp;
	  XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
	return; /* assume stack size is correct */

void
myccv_sift (object_file, scene_file, param)
	char *	object_file
	char *	scene_file
	ccv_sift_param_t *	param
	PREINIT:
	I32* temp;
	PPCODE:
	temp = PL_markstack_ptr++;
	myccv_sift(object_file, scene_file, param);
	if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
	  PL_markstack_ptr = temp;
	  XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
	return; /* assume stack size is correct */

