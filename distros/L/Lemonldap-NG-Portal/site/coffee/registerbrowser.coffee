# TOTP part inspired from https://github.com/bellstrand/totp-generator
# Copyright: 2016 Magnus Bellstrand
# License: MIT

$(document).ready ->
	if window.requestIdleCallback
		requestIdleCallback () ->
			go()
	else
		setTimeout go, 500

go = () ->
	usetotp = Boolean(parseInt($('#usetotp').attr "value"))
	if window.localStorage and usetotp
		secret = $('#totpsecret').attr "value"
		if secret
			try
				localStorage.setItem "stayconnectedkey", secret
			catch e
				console.error "Unable to register key in storage", e
		else
			secret = localStorage.getItem "stayconnectedkey"
		if secret
			try
				$('#fg').attr "value", "TOTP_#{getToken secret}"
				$('#form').submit()
				return
			catch e
				console.error "Unable to register key in storage", e

	# Load fingerprint2
	script = document.createElement 'script'
	script.src = window.staticPrefix + "bwr/fingerprintjs2/fingerprint2.js"
	script.async = false
	document.body.append script
	script.onload = tryFingerprint
	# If script not loaded after 1s, skip its load
	setTimeout tryFingerprint, 1000

tryFingerprint = () ->
	console.log "Trying fingerprint"
	if window.Fingerprint2
		Fingerprint2.get (components) ->
			values = components.map (component) =>
				component.value
			result = Fingerprint2.x64hash128(values.join(''), 31)
			$('#fg').attr "value", result
			$('#form').submit()
	else
		console.error 'No way to register this device'
		$('#form').submit()

getToken = (key) ->
	key = base32tohex key
	time = leftpad dec2hex(Math.floor(Date.now() / 30000)), 16, "0"
	shaObj = new jsSHA "SHA-1", "HEX"
	shaObj.setHMACKey key, "HEX"
	shaObj.update time
	hmac = shaObj.getHMAC "HEX"
	offset = hex2dec hmac.substring hmac.length - 1
	otp = (hex2dec(hmac.substr(offset * 2, 8)) & hex2dec("7fffffff")) + ""
	otp.substr(Math.max(otp.length - 6, 0), 6)

hex2dec = (s) ->
	parseInt s, 16

dec2hex = (s) ->
	return (if s < 15.5 then "0" else "") + Math.round(s).toString(16)

base32tohex = (base32) ->
	base32chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
	bits = ""
	hex = ""

	base32 = base32.replace(/=+$/, "")

	for i in [0 .. base32.length-1]
		val = base32chars.indexOf(base32.charAt(i).toUpperCase())
		if val == -1
			throw new Error "Invalid base32 character in key"
		bits += leftpad val.toString(2), 5, "0"

	for i in [0 .. bits.length-8] by 8
		chunk = bits.substr(i, 8)
		hex = hex + leftpad(parseInt(chunk, 2).toString(16), 2, "0")
	hex

leftpad = (str, len, pad) ->
	if len + 1 >= str.length
		str = Array(len + 1 - str.length).join(pad) + str
	str
