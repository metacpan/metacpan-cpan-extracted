# Launch SSL request

tryssl = () ->
	path = window.location.pathname
	console.log 'path -> ', path
	console.log 'Call URL -> ', window.datas.sslHost
	$.ajax window.datas.sslHost,
		dataType: 'json',
		xhrFields:
			withCredentials: true
		# If request succeed, posting form to get redirection
		# or menu
		success: (data) ->
		    # If we contain a ajax_auth_token, add it to form
			if data.ajax_auth_token
				$('#lform').find('input[name="ajax_auth_token"]').attr("value", data.ajax_auth_token)
			sendUrl path
			console.log 'Success -> ', data
		# Case else, will display PE_BADCREDENTIALS or fallback to next auth
		# backend
		error: (result) ->
			# If the AJAX query didn't fire at all, it's probably
			# a bad certificate
			if result.status == 0
				# We couldn't send the request.
				# if client verification is optional, this means
				# the certificate was rejected (or some network error)
				sendUrl path
			# For compatibility with earlier configs, handle PE9 by posting form
			if result.responseJSON && 'error' of result.responseJSON && result.responseJSON.error == "9"
				sendUrl path

			# If the server sent a html error description, display it
			if result.responseJSON && 'html' of result.responseJSON
				$('#errormsg').html(result.responseJSON.html);
				$(window).trigger('load');
			console.log 'Error during AJAX SSL authentication', result
	false

sendUrl = (path) ->
	form_url = $('#lform').attr('action')
	if form_url.match /^#$/
		form_url = path
	else
		form_url = form_url + path
	console.log 'form action URL -> ', form_url
	$('#lform').attr('action', form_url)
	$('#lform').submit()

$(document).ready ->
	$('.sslclick').on 'click', tryssl
