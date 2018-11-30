$(document).ready ->
	$(".idploop").on 'click', () ->
		$("#idp").val $(this).attr("val")
