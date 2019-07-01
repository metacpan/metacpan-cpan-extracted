# Launch SSL request

tryssl = () ->
	console.log 'Call URL -> ', window.datas.sslHost
	$.ajax window.datas.sslHost,
		dataType: 'jsonp'
		# PE_BADCREDENTIALS
		statusCode:
			401: () ->
				$('#lform').submit()
				console.log 'Error code 401'
		# If request succeed, cookie is set, posting form to get redirection
		# or menu
		success: (data) ->
			$('#lform').submit()
			console.log 'Success -> ', data
		# Case else, will display PE_BADCREDENTIALS or fallback to next auth
		# backend
		error: () ->
			$('#lform').submit()
			console.log 'Error'
	false
$(document).ready ->
	$('.sslclick').on 'click', tryssl
