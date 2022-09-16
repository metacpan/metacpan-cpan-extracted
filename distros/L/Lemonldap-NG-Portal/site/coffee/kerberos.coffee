# Launch Kerberos request

$(document).ready ->
	$.ajax (if window.location.href.match /\/(upgrade|renew)session/ then window.location.href else portal )+ '?kerberos=1',
		dataType: 'json'
		# Called if browser can't find Kerberos ticket, will display
		# PE_BADCREDENTIALS
		statusCode:
			401: () ->
				$('#lform').submit()
		# Remove upgrading flag, if set
		success: (data) ->
			$('input[name="upgrading"]').remove()
			$('#lform').submit()
		# Case else, will display PE_BADCREDENTIALS or fallback to next auth
		# backend
		error: () ->
			$('#lform').submit()
