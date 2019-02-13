# Launch Kerberos request

$(document).ready ->
	$.ajax portal + '?kerberos=1',
		dataType: 'json'
		# Called if browser can't find Kerberos ticket, will display
		# PE_BADCREDENTIALS
		statusCode:
			401: () ->
				$('#lformKerberos').submit()
		# If request succeed cookie is set, posting form to get redirection
		# or menu
		success: (data) ->
			$('#lformKerberos').submit()
		# Case else, will display PE_BADCREDENTIALS or fallback to next auth
		# backend
		error: () ->
			$('#lformKerberos').submit()
