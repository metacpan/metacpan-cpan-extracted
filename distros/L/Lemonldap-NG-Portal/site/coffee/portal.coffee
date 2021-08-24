###
LemonLDAP::NG Portal jQuery scripts
###

# Translation mechanism

translationFields = {}

# Launched at startup: download language JSON and translate all HTML tags that
# contains one of the following attributes using translate() function:
#  - trspan       : set result in tag content
#  - trmsg        : get error number and set result of PE<number> result in tag
#                   content
#  - trplaceholder: set result in "placeholder" attribute
#  - localtime    : transform time (in ms)ing translate()
translatePage = (lang) ->
	$.getJSON "#{window.staticPrefix}languages/#{lang}.json", (data) ->
		translationFields = data
		for k,v of window.datas.trOver.all
			translationFields[k] = v
		if window.datas.trOver[lang]
			for k,v of window.datas.trOver[lang]
				translationFields[k] = v
		$("[trspan]").each ->
			args = $(this).attr('trspan').split(',')
			txt = translate args.shift()
			for v in args
				txt = txt.replace /%[sd]/, v
			$(this).html txt
		$("[trmsg]").each ->
			$(this).html translate "PE#{$(this).attr 'trmsg'}"
			msg = translate "PE#{$(this).attr 'trmsg'}"
			if msg.match /_hide_/
				$(this).parent().hide()
		$("[trplaceholder]").each ->
			$(this).attr 'placeholder', translate($(this).attr('trplaceholder'))
		$("[localtime]").each ->
			d = new Date $(this).attr('localtime') * 1000
			$(this).text d.toLocaleString()

# Translate a string
translate = (str) ->
	return if translationFields[str] then translationFields[str] else str

window.translate = translate

# Initialization variables: read all <script type="application/init"> tags and
# return JSON parsing result. This is set in window.data variable
getValues = () ->
	values = {}
	$("script[type='application/init']").each ->
		try
			tmp = JSON.parse $(this).text()
			for k of tmp
				values[k] = tmp[k]
		catch e
			console.log 'Parsing error', e
			console.log 'JSON', $(this).text()
	console.log values
	values

# Gets a query string parametrer
# We cannot use URLSearchParam because of IE (#2230)
getQueryParam = (name) ->
	match = RegExp('[?&]' + name + '=([^&]*)').exec(window.location.search)
	if match then decodeURIComponent(match[1].replace(/\+/g, ' ')) else null


# Code from http://snipplr.com/view/29434/
# ----------------------------------------
setSelector = "#appslist"

# Function to write the sorted apps list to session (network errors ignored)
setOrder = ->
	setKey '_appsListOrder', $(setSelector).sortable("toArray").join()

# Function used to remove an OIDC consent
removeOidcConsent = (partner) ->
	#r = new RegExp "\b#{partner}\b,?", 'g'
	#datas['oidcConsents'] = datas['oidcConsents'].replace(r,'').replace(/,$/,'')
	#setKey '_oidcConnectedRP', datas['oidcConsents']
	#	# Success
	#	, () ->
	#		$("[partner='#{partner}']").hide()
	#	# Error
	#	, (j,s,e) ->
	#		alert "#{s} #{e}"
	e = (j,s,e) ->
		alert "#{s} #{e}"
	delKey "_oidcConsents",partner
		# Success
		, () ->
			$("[partner='#{partner}']").hide()
		# Error
		, e

# Function used by setOrder() and removeOidcConsent() to push new values
# For security reason, modification is rejected unless a valid token is given
setKey = (key,val,success,error) ->
	# First request to get token
	$.ajax
		type: "GET"
		url: datas['scriptname'] + '/mysession/?gettoken'
		dataType: 'json'
		error: error
		# On success, value is set
		success: (data) ->
			d =
				token: data.token
			d[key] = val
			$.ajax
				type: "PUT"
				url: datas['scriptname'] + '/mysession/persistent'
				dataType: 'json'
				data: d
				success: success
				error: error

delKey = (key,sub,success,error) ->
	$.ajax
		type: "GET"
		url: datas['scriptname'] + '/mysession/?gettoken'
		dataType: 'json'
		error: error
		# On success, value is set
		success: (data) ->
			$.ajax
				type: "DELETE"
				url: "#{datas['scriptname']}/mysession/persistent/#{key}?sub=#{sub}&token=#{data.token}"
				dataType: 'json'
				success: success
				error: error

# function that restores the list order from session
restoreOrder = ->
	list = $(setSelector)
	return null unless list? and datas['appslistorder']

	# make array from saved order
	IDs = datas['appslistorder'].split ','

	# fetch current order
	items = list.sortable "toArray"

	# make array from current order
	rebuild = []
	for v in items
		rebuild[v] = v

	for itemID in IDs
		if rebuild[itemID]

			# select item id from current order
			item = rebuild[itemID]

			# select the item according to current order
			child = $(setSelector + ".ui-sortable").children "#" + item

			# select the item according to the saved order
			savedOrd = $(setSelector + ".ui-sortable").children "#" + itemID

			# remove all the items
			child.remove()

			# add the items in turn according to saved order
			# we need to filter here since the "ui-sortable"
			# class is applied to all ul elements and we
			# only want the very first! You can modify this
			# to support multiple lists - not tested!
			$(setSelector + ".ui-sortable").filter(":first").append savedOrd
	1

# function boolean isHiddenFormValueSet(string option)
# Check if an hidden option is set
# @param option Option name
# @return true if option is set, false else
isHiddenFormValueSet = (option) ->
	return $('#lmhidden_' + option).length

# function void ping()
# Check if session is alive on server side
# @return nothing
ping = ->
	$.ajax
		type: "POST"
		url: datas['scriptname']
		data:
			ping: 1
		dataType: 'json'
		success: (data) ->
			if data.result? and data.result == 1
				setTimeout ping, datas['pingInterval']
			else
				location.reload true
		error: (j,t,e) ->
			location.reload true

window.ping = ping

# Functions to get/set a cookie value
getCookie = (cname) ->
	name = cname + "="
	ca = decodeURIComponent(document.cookie).split ';'
	re = new RegExp('^ *'+cname+'=')
	for c in ca
		if c.match re
			c = c.replace re, ''
			return c
	return ''

setCookie = (name, value, exdays) ->
	d = new Date()
	d.setTime d.getTime() + exdays*86400000
	document.cookie = "#{name}=#{value}; expires=#{d.toUTCString()}; path=/"

# Function to change password using Ajax (instead of POST)
# NOT USED FOR NOW
#changePwd = (event) ->
#	event.preventDefault()
#	$.ajax
#		type: 'POST'
#		url: datas['scriptname']
#		dataType: 'json'
#		data:
#			oldpassword: $('#oldpassword').val()
#			newpassword: $('#newpassword').val()
#			confirmpassword: $('#confirmpassword').val()
#		success: (data) ->
#			console.log "R", data

# Initialization
datas = {}

$(window).on 'load', () ->
	# Get application/init variables
	datas = getValues()

	# Keep the currently selected tab
	if "datas" of window && "choicetab" of window.datas
		datas.choicetab = window.datas.choicetab;

	# Export datas for other scripts
	window.datas = datas

	$("#appslist").sortable
		axis: "y"
		cursor: "move"
		opacity: 0.5
		revert: true
		items: "> div.category"
		update: ->
			setOrder()

	restoreOrder()

	$("div.message").fadeIn 'slow'

	# Set timezone
	$("input[name=timezone]").val -(new Date().getTimezoneOffset() / 60)

	# Menu tabs
	menuTabs = $("#menu").tabs
		active: 0
	menuIndex = $('#menu a[href="#' + datas['displaytab'] + '"]').parent().index()
	menuIndex = 0 if menuIndex < 0
	menuTabs.tabs "option", "active", menuIndex

	# Authentication choice tabs
	authMenuTabs = $("#authMenu").tabs
		active: 0
	authMenuIndex = $('#authMenu a[href="#' + datas['displaytab'] + '"]').parent().index()
	authMenuIndex = 0 if authMenuIndex < 0
	authMenuTabs.tabs "option", "active", authMenuIndex

	# TODO: cookie
	# $("#authMenu").tabs
	# 	cookie:
	# 		name: 'lemonldapauthchoice'
	if datas['choicetab']
		authMenuTabs.tabs "option", "active", $('#authMenu a[href="#' + datas['choicetab'] + '"]').parent().index()

	if datas['login']
		$("input[type=password]:first").focus()
	else
		# If there are no auto-focused fields, focus on first visible input
		if $("input[autofocus]").length == 0
			$("input[type!=hidden]:first").focus();

	# Open links in new windows if required
	if datas['newwindow']
		$('#appslist a').attr "target", "_blank"

	# Complete removeOther link
	if $("p.removeOther").length
		action = $("#form").attr "action"
		method = $("#form").attr "method"
		console.log 'method=', method

		hiddenParams = ""
		if $("#form input[type=hidden]")
			console.log 'Parse hidden values' 
			$("#form input[type=hidden]").each (index) ->
				console.log ' ->', $(this).attr("name"), $(this).val()
				hiddenParams +=  "&" + $(this).attr("name") + "=" + $(this).val()

		back_url = ""
		if action
			console.log 'action=', action
			if action.indexOf("?") != -1
				action.substring(0, action.indexOf("?")) + "?"
			else
				back_url = action + "?"
			back_url += hiddenParams
			hiddenParams = ""

		link = $("p.removeOther a").attr("href") + "&method=" + method + hiddenParams
		link += "&url=" + btoa(back_url) if back_url
		$("p.removeOther a").attr "href", link

	# Language detection. Priority order:
	#  0 - llnglanguage parameter
	#  1 - cookie value
	#  2 - first navigator.languages item that exists in window.availableLanguages
	#  3 - first value of window.availableLanguages
	if window.location.search
		queryLang = getQueryParam('llnglanguage')
		console.log 'Get lang from parameter' if queryLang
		setCookieLang = getQueryParam('setCookieLang')
		console.log 'Set lang cookie' if setCookieLang == 1
	if !lang
		lang = getCookie 'llnglanguage'
		console.log 'Get lang from cookie' if lang && !queryLang
	if !lang
		if navigator
			langs = []
			langs2 = []
			nlangs = [ navigator.language ]
			if navigator.languages
				nlangs = navigator.languages
			for al in window.availableLanguages
				langdiv += "<img class=\"langicon\" src=\"#{window.staticPrefix}common/#{al}.png\" title=\"#{al}\" alt=\"[#{al}]\"> "
			for nl in nlangs
				console.log 'Navigator lang', nl
				for al in window.availableLanguages
					console.log ' Available lang', al
					re = new RegExp('^'+al+'-?')
					if nl.match re
						console.log '  Matching lang =', al
						langs.push al
					else if al.substring(0, 1) == nl.substring(0, 1)
						langs2.push al
			lang = if langs[0] then langs[0] else if langs2[0] then langs2[0] else window.availableLanguages[0]
			console.log 'Get lang from navigator' if lang && !queryLang
		else
			lang = window.availableLanguages[0]
			console.log 'Get lang from window' if lang && !queryLang
	else if lang not in window.availableLanguages
		lang = window.availableLanguages[0]
		console.log 'Lang not available -> Get default lang' if !queryLang
	if queryLang
		if queryLang not in window.availableLanguages
			console.log 'Lang not available -> Get default lang'
			queryLang = window.availableLanguages[0]
		console.log 'Selected lang ->', queryLang
		if setCookieLang
			console.log 'Set cookie lang ->', queryLang
			setCookie 'llnglanguage', queryLang
		translatePage(queryLang)
	else
		console.log 'Selected lang ->', lang
		setCookie 'llnglanguage', lang
		translatePage(lang)

	# Build language icons
	langdiv = ''
	for al in window.availableLanguages
		langdiv += "<img class=\"langicon\" src=\"#{window.staticPrefix}common/#{al}.png\" title=\"#{al}\" alt=\"[#{al}]\"> "
	$('#languages').html langdiv
	$('.langicon').on 'click', () ->
		lang = $(this).attr 'title'
		setCookie 'llnglanguage', lang
		translatePage lang

	isAlphaNumeric = (chr) ->
		code = chr.charCodeAt(0)
		if code > 47 and code < 58 or code > 64 and code < 91 or code > 96 and code < 123
			return true
		false

	# Password policy
	checkpassword = (password) ->
		result = true
		if window.datas.ppolicy.minsize > 0
			if password.length >= window.datas.ppolicy.minsize
				$('#ppolicy-minsize-feedback').addClass 'fa-check text-success'
				$('#ppolicy-minsize-feedback').removeClass 'fa-times text-danger'
			else
				$('#ppolicy-minsize-feedback').removeClass 'fa-check text-success'
				$('#ppolicy-minsize-feedback').addClass 'fa-times text-danger'
				result = false
		if window.datas.ppolicy.minupper > 0
			upper = password.match(/[A-Z]/g)
			if upper and upper.length >= window.datas.ppolicy.minupper
				$('#ppolicy-minupper-feedback').addClass 'fa-check text-success'
				$('#ppolicy-minupper-feedback').removeClass 'fa-times text-danger'
			else
				$('#ppolicy-minupper-feedback').removeClass 'fa-check text-success'
				$('#ppolicy-minupper-feedback').addClass 'fa-times text-danger'
				result = false
		if window.datas.ppolicy.minlower > 0
			lower = password.match(/[a-z]/g)
			if lower and lower.length >= window.datas.ppolicy.minlower
				$('#ppolicy-minlower-feedback').addClass 'fa-check text-success'
				$('#ppolicy-minlower-feedback').removeClass 'fa-times text-danger'
			else
				$('#ppolicy-minlower-feedback').removeClass 'fa-check text-success'
				$('#ppolicy-minlower-feedback').addClass 'fa-times text-danger'
				result = false
		if window.datas.ppolicy.mindigit > 0
			digit = password.match(/[0-9]/g)
			if digit and digit.length >= window.datas.ppolicy.mindigit
				$('#ppolicy-mindigit-feedback').addClass 'fa-check text-success'
				$('#ppolicy-mindigit-feedback').removeClass 'fa-times text-danger'
			else
				$('#ppolicy-mindigit-feedback').removeClass 'fa-check text-success'
				$('#ppolicy-mindigit-feedback').addClass 'fa-times text-danger'
				result = false

		if window.datas.ppolicy.allowedspechar
			nonwhitespechar = window.datas.ppolicy.allowedspechar.replace(/\s/g, '')
			hasforbidden = false
			i = 0
			len = password.length
			while i < len
				if !isAlphaNumeric(password.charAt(i))
					if nonwhitespechar.indexOf(password.charAt(i)) < 0
						hasforbidden = true
				i++
			if hasforbidden == false
				$('#ppolicy-allowedspechar-feedback').addClass 'fa-check text-success'
				$('#ppolicy-allowedspechar-feedback').removeClass 'fa-times text-danger'
			else
				$('#ppolicy-allowedspechar-feedback').removeClass 'fa-check text-success'
				$('#ppolicy-allowedspechar-feedback').addClass 'fa-times text-danger'
				result = false

		if window.datas.ppolicy.minspechar > 0 and window.datas.ppolicy.allowedspechar
			numspechar = 0
			nonwhitespechar = window.datas.ppolicy.allowedspechar.replace(/\s/g, '')
			i = 0
			while i < password.length
				if nonwhitespechar.indexOf(password.charAt(i)) >= 0
					numspechar++
				i++
			if numspechar >= window.datas.ppolicy.minspechar
				$('#ppolicy-minspechar-feedback').addClass 'fa-check text-success'
				$('#ppolicy-minspechar-feedback').removeClass 'fa-times text-danger'
			else
				$('#ppolicy-minspechar-feedback').removeClass 'fa-check text-success'
				$('#ppolicy-minspechar-feedback').addClass 'fa-times text-danger'
				result = false

		if window.datas.ppolicy.minspechar > 0 and !window.datas.ppolicy.allowedspechar
			numspechar = 0
			i = 0
			while i < password.length
				numspechar++ if !isAlphaNumeric(password.charAt(i))
				i++
			if numspechar >= window.datas.ppolicy.minspechar
				$('#ppolicy-minspechar-feedback').addClass 'fa-check text-success'
				$('#ppolicy-minspechar-feedback').removeClass 'fa-times text-danger'
			else
				$('#ppolicy-minspechar-feedback').removeClass 'fa-check text-success'
				$('#ppolicy-minspechar-feedback').addClass 'fa-times text-danger'
				result = false

		if result
			$('.ppolicy').removeClass('border-danger').addClass 'border-success'
			$('#newpassword').get(0)?.setCustomValidity('')
		else
			$('.ppolicy').removeClass('border-success').addClass 'border-danger'
			$('#newpassword').get(0)?.setCustomValidity(translate('PE28'))
		return

	if window.datas.ppolicy? and $('#newpassword').length
		# Initialize display
		checkpassword ''

		$('#newpassword').keyup (e) ->
			checkpassword e.target.value
			return

	# If generating password, disable policy check
	togglecheckpassword = (e) ->
		if e.target.checked
			$('#newpassword').off('keyup')
			$('#newpassword').get(0)?.setCustomValidity('')
		# Restore check
		else
			$('#newpassword').keyup (e) ->
				checkpassword e.target.value
				return
			checkpassword ''

	checksamepass = () ->
		if $('#confirmpassword').get(0)?.value == $('#newpassword').get(0)?.value
			$('#confirmpassword').get(0)?.setCustomValidity('')
			return true
		else
			$('#confirmpassword').get(0)?.setCustomValidity(translate('PE34'))
			return false

	$('#newpassword').change checksamepass
	$('#confirmpassword').change checksamepass
	if window.datas.ppolicy? and $('#newpassword').length
		$('#reset').change togglecheckpassword

	# Functions to show/hide display password button
	if datas['enablePasswordDisplay']
		if datas['dontStorePassword']
			$(".toggle-password").mousedown () ->
				$(this).toggleClass("fa-eye fa-eye-slash")
				$("input[name=password]").attr('class', 'form-control')
			$(".toggle-password").mouseup () ->
				$(this).toggleClass("fa-eye fa-eye-slash")
				$("input[name=password]").attr('class', 'form-control key') if $("input[name=password]").get(0).value 
		else
			$(".toggle-password").mousedown () ->
				$(this).toggleClass("fa-eye fa-eye-slash")
				$("input[name=password]").attr("type", "text")
			$(".toggle-password").mouseup () ->
				$(this).toggleClass("fa-eye fa-eye-slash")
				$("input[name=password]").attr("type", "password")

	# Ping if asked
	if datas['pingInterval'] and datas['pingInterval'] > 0
		window.setTimeout ping, datas['pingInterval']

	# Set local dates (used to display history)
	$(".localeDate").each ->
		s = new Date($(this).attr("val")*1000)
		$(this).text s.toLocaleString()

	$('.oidcConsent').on 'click', () ->
		removeOidcConsent $(this).attr 'partner'

	# Functions to show/hide change password inputs
	$('#show-hide-button').on 'click', () ->
		if datas['dontStorePassword']
			if  $("#newpassword").attr('class') == 'form-control key' || $("#confirmpassword").attr('class') == 'form-control key'
				console.log 'Show passwords'
				$("#newpassword").attr('class', 'form-control')
				$("#confirmpassword").attr('class', 'form-control')
				$("#show-hide-icon-button").attr('class', 'fa fa-eye-slash')
			else
				console.log 'Hide passwords'
				$("#newpassword").attr('class', 'form-control key') if $("#newpassword").get(0).value
				$("#confirmpassword").attr('class', 'form-control key') if $("#confirmpassword").get(0).value
				$("#show-hide-icon-button").attr('class', 'fa fa-eye') if ($("#newpassword").get(0).value || $("#confirmpassword").get(0).value)
		else
			if  $("#newpassword").attr('type') == 'password'
				console.log 'Show passwords'
				$("#newpassword").attr('type', 'text')
				$("#confirmpassword").attr('type', 'text')
				$("#show-hide-icon-button").attr('class', 'fa fa-eye-slash')
			else
				console.log 'Hide passwords'
				$("#newpassword").attr('type', 'password')
				$("#confirmpassword").attr('type', 'password')
				$("#show-hide-icon-button").attr('class', 'fa fa-eye')

	# Functions to show/hide placeholder password inputs
	$('#passwordfield').on 'input', () ->
		if $('#passwordfield').get(0).value && datas['dontStorePassword']
			$("#passwordfield").attr('class', 'form-control key')
		else
			$("#passwordfield").attr('class', 'form-control')
	$('#oldpassword').on 'input', () ->
		if $('#oldpassword').get(0).value && datas['dontStorePassword']
			$("#oldpassword").attr('class', 'form-control key')
		else
			$("#oldpassword").attr('class', 'form-control')
	$('#newpassword').on 'input', () ->
		if $('#newpassword').get(0).value && datas['dontStorePassword']
			$("#newpassword").attr('class', 'form-control key') if $("#show-hide-icon-button").attr('class') == 'fa fa-eye'
		else
			$("#newpassword").attr('class', 'form-control')
	$('#confirmpassword').on 'input', () ->
		if $('#confirmpassword').get(0).value && datas['dontStorePassword']
			$("#confirmpassword").attr('class', 'form-control key') if $("#show-hide-icon-button").attr('class') == 'fa fa-eye'
		else
			$("#confirmpassword").attr('class', 'form-control')

	#$('#formpass').on 'submit', changePwd

	$('.clear-finduser-field').on 'click', () ->
		$(this).parent().find(':input').each ->
			console.log 'Clear search field ->', $(this).attr 'name'
			$(this).val ''

	$('#closefinduserform').on 'click', () ->
		console.log 'Clear modal'
		$('#finduserForm').trigger('reset')

	$('#finduserbutton').on 'click', (event) ->
		event.preventDefault()
		document.body.style.cursor = 'progress'
		str = $("#finduserForm").serialize()
		console.log 'Send findUser request with parameters', str
		$.ajax
			type: "POST"
			url: "#{portal}finduser"
			dataType: 'json'
			data: str
			# On success, values are set
			success: (data) ->
				document.body.style.cursor = 'default'
				user = data.user
				console.log 'Suggested spoofId=', user
				$("input[name=spoofId]").each ->
					$(this).attr 'value', user
				$('#captcha').attr 'src', data.captcha if data.captcha
				if data.token
					$('#finduserToken').attr 'value', data.token 
					$('#token').attr 'value', data.token
			error: (j, status, err) ->
				document.body.style.cursor = 'default'
				console.log 'Error', err  if err
				res = JSON.parse j.responseText if j
				if res and res.error
					console.log 'Returned error', res
