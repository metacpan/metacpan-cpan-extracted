# Launch Kerberos request

$(document).ready ->
	$.ajax portal + 'authkrb',
		dataType: 'json'
		# Called if browser can't find Kerberos ticket, will display
		# PE_BADCREDENTIALS
		statusCode:
			401: () ->
				$('#lform').submit()
		# Remove upgrading flag, if set
		success: (data) ->
			if data.ajax_auth_token
				$('#lform').find('input[name="ajax_auth_token"]').attr("value", data.ajax_auth_token)
			$('#lform').submit()
		# Case else, will display PE_BADCREDENTIALS or fallback to next auth
		# backend
		error: () ->
			$('#lform').submit()
