$(document).ready ->
	new Fingerprint2().get (result, components) ->
		$('#fg').attr "value", result
		$('#form').submit()
