# Launch Kerberos request

$(document).ready ->
	$.ajax portal + '/authkrb',
		dataType: 'json'
		# Called if browser can't find Kerberos ticket, will display
		# PE_BADCREDENTIALS
		statusCode:
			401: () ->
				$('#lformKerberos').submit()
		# If request succeed cookie is set, posting form to get redirection
		# or menu
		success: (data) ->
			if data.ajax_auth_token
				$('#lformKerberos').find('input[name="ajax_auth_token"]').attr("value", data.ajax_auth_token)
			$('#lformKerberos').submit()
		# Case else, will display PE_BADCREDENTIALS or fallback to next auth
		# backend
		error: () ->
			$('#lformKerberos').submit()
