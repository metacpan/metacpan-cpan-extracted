# Launch Kerberos request

$(document).ready ->
	$.ajax (if window.location.href.match /\/upgradesession/ then window.location.href else portal )+ '?kerberos=1',
		dataType: 'json'
		# Called if browser can't find Kerberos ticket, will display
		# PE_BADCREDENTIALS
		statusCode:
			401: () ->
				$('#lform').submit()
		# If request succeed cookie is set, posting form to get redirection
		# or menu
		success: (data) ->
            if window.location.href.match /\/upgradesession/
                document.location = portal
            else
                $('#lform').submit()
		# Case else, will display PE_BADCREDENTIALS or fallback to next auth
		# backend
		error: () ->
			$('#lform').submit()
