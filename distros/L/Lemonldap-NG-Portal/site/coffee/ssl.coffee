# Launch SSL request

tryssl = () ->
	$.ajax window.datas.sslHost,
		dataType: 'json'
		# Called if browser can't find Kerberos ticket will display
		# PE_BADCREDENTIALS
		statusCode:
			401: () ->
				$('#lform').submit()
		# If request succeed, cookie is set, posting form to get redirection
		# or menu
		success: (data) ->
			$('#lform').submit()
		# Case else, will display PE_BADCREDENTIALS or fallback to next auth
		# backend
		error: () ->
			$('#lform').submit()

$(document).ready ->
	$('.sslclick').on 'click', tryssl
