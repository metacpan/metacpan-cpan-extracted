# Launch Kerberos request

$(document).ready ->
	e = jQuery.Event( "kerberosAttempt" )
	$(document).trigger e
	if !e.isDefaultPrevented()
		$.ajax "#{portal}authkrb",
			dataType: 'json'
			# Get auth token from success response and post it
			success: (data) ->
				e = jQuery.Event( "kerberosSuccess" )
				$(document).trigger e, [ data ]
				if !e.isDefaultPrevented()
					if data.ajax_auth_token
						$('#lformKerberos').find('input[name="ajax_auth_token"]').attr("value", data.ajax_auth_token)
					$('#lformKerberos').submit()
			# Case else, will display PE_BADCREDENTIALS or fallback to next auth
			# backend
			error: (xhr, status, error) ->
				e = jQuery.Event( "kerberosFailure" )
				$(document).trigger e, [ xhr, status, error ]
				if !e.isDefaultPrevented()
					$('#lformKerberos').submit()
