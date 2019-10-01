# Launch SSL request

tryssl = () ->
	path = window.location.pathname
	console.log 'path -> ', path
	console.log 'Call URL -> ', window.datas.sslHost
	$.ajax window.datas.sslHost,
		dataType: 'jsonp'
		# PE_BADCREDENTIALS
		statusCode:
			401: () ->
				$('#lformSSL').submit()
				console.log 'Error code 401'
		# If request succeed, cookie is set, posting form to get redirection
		# or menu
		success: (data) ->
			sendUrl path
			console.log 'Success -> ', data
		# Case else, will display PE_BADCREDENTIALS or fallback to next auth
		# backend
		error: () ->
			sendUrl path
			console.log 'Error'
	false

sendUrl = (path) ->
	form_url = $('#lformSSL').attr('action')
	if form_url.match /^#$/
		form_url = path
	else
		form_url = form_url + path
	console.log 'form action URL -> ', form_url
	$('#lformSSL').attr('action', form_url)
	$('#lformSSL').submit()

$(document).ready ->
	$('.sslclick').on 'click', tryssl