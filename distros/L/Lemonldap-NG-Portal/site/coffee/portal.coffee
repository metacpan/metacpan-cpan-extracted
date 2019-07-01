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
#	event.preventDefault();
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
$(document).ready ->
	# Get application/init variables
	datas = getValues()
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

	# TODO: cookie
	# $("#authMenu").tabs
	# 	cookie:
	# 		name: 'lemonldapauthchoice'
	if datas['choicetab']
		authMenuTabs.tabs "option", "active", $('#authMenu a[href="#' + datas['choicetab'] + '"]').parent().index()

	if datas['login']
		$("input[type=password]:first").focus()
	else
		# Focus on first visible input
		$("input[type!=hidden]:first").focus()

	# Open links in new windows if required
	if datas['newwindow']
		$('#appslist a').attr "target", "_blank"

	# Complete removeOther link
	if $("p.removeOther").length
		action = $("form.login").attr "action"
		method = $("form.login").attr "method"

		back_url = ""
		if action.indexOf("?") != -1
			action.substring(0, action.indexOf("?")) + "?"
		else
			back_url = action + "?"

		$("form.login input[type=hidden]").each (index) ->
			back_url +=  "&" + $(this).attr("name") + "=" + $(this).val()

		link = $("p.removeOther a").attr("href") + "&method=" + method + "&url=" + btoa(back_url)
		$("p.removeOther a").attr "href", link

	# Language detection. Priority order:
	#  1 - cookie value
	#  2 - first navigator.languages item that exists in window.availableLanguages
	#  3 - first value of window.availableLanguages
	lang = getCookie 'llnglanguage'
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
		else
			lang = window.availableLanguages[0]
	else if lang not in window.availableLanguages
		lang = window.availableLanguages[0]
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

	# Ping if asked
	if datas['pingInterval'] and datas['pingInterval'] > 0
		window.setTimeout ping, datas['pingInterval']

	# Set local dates (used to display history)
	$(".localeDate").each ->
		s = new Date($(this).attr("val")*1000)
		$(this).text s.toLocaleString()

	$('.oidcConsent').on 'click', () ->
		removeOidcConsent $(this).attr 'partner'

	#$('#formpass').on 'submit', changePwd
