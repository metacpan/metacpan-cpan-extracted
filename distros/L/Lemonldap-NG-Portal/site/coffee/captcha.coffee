# Launch renew captcha request

renewCaptcha = () ->
	console.log 'Call URL -> ', "#{portal}renewcaptcha"
	# Request to get new token and image
	$.ajax
		type: "GET"
		url: "#{portal}renewcaptcha"
		dataType: 'json'
		error: (j, status, err) ->
			console.log 'Error', err if err
			res = JSON.parse j.responseText if j
			if res and res.error
				console.log 'Returned error', res
		# On success, values are set
		success: (data) ->
			newtoken = data.newtoken
			console.log 'GET new token -> ', newtoken
			newimage = data.newimage
			console.log 'GET new image -> ', newimage
			$('#token').attr 'value', newtoken
			$('#captcha').attr 'src', newimage

$(document).ready ->
	$('#logout').attr 'href', portal
	$('.renewcaptchaclick').on 'click', renewCaptcha