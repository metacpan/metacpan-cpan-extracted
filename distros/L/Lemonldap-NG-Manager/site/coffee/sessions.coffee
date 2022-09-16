###
# Sessions explorer
###

# Max number of session to display (see overScheme)
max = 25

# Queries to do each type of display: each array item corresponds to the depth
# of opened nodes in the tree
schemes =
	_whatToTrace: [
		# First level: display 1 letter
		(t,v) ->
			"groupBy=substr(#{t},1)"
		# Second level (if no overScheme), display usernames
		(t,v) ->
			"#{t}=#{v}*&groupBy=#{t}"
		(t,v) ->
			"#{t}=#{v}"
	]
	ipAddr: [
		(t,v) ->
			"groupBy=net(#{t},16,1)"
		(t,v) ->
			v = v + '.' unless v.match /:/
			"#{t}=#{v}*&groupBy=net(#{t},32,2)"
		(t,v) ->
			v = v + '.' unless v.match /:/
			"#{t}=#{v}*&groupBy=net(#{t},48,3)"
		(t,v) ->
			v = v + '.' unless v.match /:/
			"#{t}=#{v}*&groupBy=net(#{t},128,4)"
		(t,v) ->
			"#{t}=#{v}&groupBy=_whatToTrace"
		(t,v,q) ->
			q.replace(/\&groupBy.*$/, '') + "&_whatToTrace=#{v}"
	]
	_startTime: [
		(t,v) ->
			"groupBy=substr(#{t},8)"
		(t,v) ->
			"#{t}=#{v}*&groupBy=substr(#{t},10)"
		(t,v) ->
			"#{t}=#{v}*&groupBy=substr(#{t},11)"
		(t,v) ->
			"#{t}=#{v}*&groupBy=substr(#{t},12)"
		(t,v) ->
			"#{t}=#{v}*&groupBy=_whatToTrace"
		(t,v,q) ->
			console.log t
			console.log v
			console.log q
			q.replace(/\&groupBy.*$/, '') + "&_whatToTrace=#{v}"
	]
	doubleIp: [
		(t,v) ->
			t
		(t,v) ->
			"_whatToTrace=#{v}&groupBy=ipAddr"
		(t,v,q) ->
			q.replace(/\&groupBy.*$/, '') + "&ipAddr=#{v}"
	]
	_session_uid: [
		# First level: display 1 letter
		(t,v) ->
			"groupBy=substr(#{t},1)"
		# Second level (if no overScheme), display usernames
		(t,v) ->
			"#{t}=#{v}*&groupBy=#{t}"
		(t,v) ->
			"#{t}=#{v}"
	]

# When number of children nodes exceeds "max" value and if "overScheme.<type>"
# is available and does not return "null", a level is added. See
# "$scope.updateTree" method
overScheme =
	_whatToTrace: (t,v,level,over) ->
		# "v.length > over" avoids a loop if one user opened more than "max"
		# sessions
		console.log 'overScheme => level', level, 'over', over
		if level == 1 and v.length > over
			"#{t}=#{v}*&groupBy=substr(#{t},#{(level+over+1)})"
		else
			null
	# Note: IPv4 only
	ipAddr: (t,v,level,over) ->
		console.log 'overScheme => level', level, 'over', over
		if level > 0 and level < 4 and !v.match(/^\d+\.\d/) and over < 2
			"#{t}=#{v}*&groupBy=net(#{t},#{16*level+4*(over+1)},#{1+level+over})"
		else
			null
	_startTime: (t,v,level,over) ->
		console.log 'overScheme => level', level, 'over', over
		if level > 3
			"#{t}=#{v}*&groupBy=substr(#{t},#{(10+level+over)})"
		else
			null
	_session_uid: (t,v,level,over) ->
		console.log 'overScheme => level', level, 'over', over
		if level == 1 and v.length > over
			"#{t}=#{v}*&groupBy=substr(#{t},#{(level+over+1)})"
		else
			null

hiddenAttributes = '_password'

# Attributes to group in session display
categories =
    dateTitle:          ['_utime', '_startTime', '_updateTime', '_lastAuthnUTime', '_lastSeen']
    connectionTitle:    ['ipAddr', '_timezone', '_url']
    authenticationTitle:['_session_id', '_user', '_password', 'authenticationLevel']
    modulesTitle:       ['_auth', '_userDB', '_passwordDB', '_issuerDB', '_authChoice', '_authMulti', '_userDBMulti', '_2f']
    saml:               ['_idp', '_idpConfKey', '_samlToken', '_lassoSessionDump', '_lassoIdentityDump']
    groups:             ['groups', 'hGroups']
    ldap:               ['dn']
    OpenIDConnect:      ['_oidc_id_token', '_oidc_OP', '_oidc_access_token', '_oidc_refresh_token', '_oidc_access_token_eol']
    sfaTitle:			['_2fDevices']
    oidcConsents:		['_oidcConsents']

# Menu entries
menu =
	session: [
		title: 'deleteSession'
		icon:  'trash'
	]
	home: []

###
# AngularJS application
###
llapp = angular.module 'llngSessionsExplorer', ['ui.tree', 'ui.bootstrap', 'llApp']

# Main controller
llapp.controller 'SessionsExplorerCtrl', ['$scope', '$translator', '$location', '$q', '$http', ($scope, $translator, $location, $q, $http) ->
	$scope.links = links
	$scope.menulinks = menulinks
	$scope.staticPrefix = staticPrefix
	$scope.scriptname = scriptname
	$scope.formPrefix = formPrefix
	$scope.impPrefix = impPrefix
	$scope.sessionTTL = sessionTTL
	$scope.availableLanguages = availableLanguages
	$scope.waiting = true
	$scope.showM = false
	$scope.showT = true
	$scope.data = []
	$scope.currentScope = null
	$scope.currentSession = null
	$scope.menu = menu

	# Import translations functions
	$scope.translateP = $translator.translateP
	$scope.translate = $translator.translate
	$scope.translateTitle = (node) ->
		$translator.translateField node, 'title'
	sessionType = 'global'

	# Handle menu items
	$scope.menuClick = (button) ->
		if button.popup
			window.open button.popup
		else
			button.action = button.title unless button.action
			switch typeof button.action
				when 'function'
					button.action $scope.currentNode, $scope
				when 'string'
					$scope[button.action]()
				else
					console.log typeof button.action
		$scope.showM = false

	# SESSION MANAGEMENT

	# Delete RP Consent
	$scope.deleteOIDCConsent = (rp, epoch) ->
		items = document.querySelectorAll(".data-#{epoch}")
		$scope.waiting = true
		$http['delete']("#{scriptname}sessions/OIDCConsent/#{sessionType}/#{$scope.currentSession.id}?rp=#{rp}&epoch=#{epoch}").then (response) ->
			$scope.waiting = false
			for e in items
				e.remove()
		, (resp) ->
			$scope.waiting = false
		$scope.showT = false

	# Delete
	$scope.deleteSession = ->
		$scope.waiting = true
		$http['delete']("#{scriptname}sessions/#{sessionType}/#{$scope.currentSession.id}").then (response) ->
			$scope.currentSession = null
			$scope.currentScope.remove()
			$scope.waiting = false
		, (resp) ->
			$scope.waiting = false

	# Open node
	$scope.stoggle = (scope) ->
		node = scope.$modelValue
		if node.nodes.length == 0
			$scope.updateTree node.value, node.nodes, node.level, node.over, node.query, node.count
		scope.toggle()

	# Display selected session
	$scope.displaySession = (scope) ->

		# Private functions

		# Session preparation
		transformSession = (session) ->
			_insert = (re, title) ->
				tmp = []
				reg = new RegExp(re)
				cv  = ""
				for key,value of session
					if key.match(reg) and value
						cv += "#{value}:#{key},"
						delete session[key]
				if cv
					cv = cv.replace(/,$/, '')
					tab = cv.split ','
					tab.sort()
					tab.reverse()
					for val in tab
						vk = val.split ':'
						tmp.push
							title: vk[1]
							value: $scope.localeDate vk[0]
					res.push
						title: title
						nodes: tmp
			time = session._utime

			# 1. Replace values if needed
			for key, value of session
				unless value
					delete session[key]
				else
					if typeof session == 'string' and value.match(/; /)
						session[key] = value.split '; '
					if typeof session[key] != 'object'
						if hiddenAttributes.match(new RegExp('\b' + key + '\b'))
							session[key] = '********'
						else if key.match /^(_utime|_lastAuthnUTime|_lastSeen|notification)$/
							session[key] = $scope.localeDate value
						else if key.match /^(_startTime|_updateTime)$/
							session[key] = $scope.strToLocaleDate value

			res = []

			# 2. Push session keys in result, grouped by categories
			for category, attrs of categories
				subres = []
				for attr in attrs
					if session[attr]
						if attr == "_2fDevices" && session[attr]
							array = JSON.parse(session[attr])
							if array.length > 0
								subres.push
									title: "type"
									value: "name"
									epoch: "date"
									td: "0"
								for sfDevice in array
									for key, value of sfDevice
										if key == 'type'
											title = value
										if key == 'name'
											name = value
										if key == 'epoch'
											epoch = value
									subres.push
										title: title
										value: name
										epoch: epoch
										td: "1"
							delete session[attr]
						else if session[attr].toString().match(/"rp":\s*"[\w-]+"/)
							subres.push
								title: "RP"
								value: "scope"
								epoch: "date"
								td: "0"
							array = JSON.parse(session[attr])
							for oidcConsent in array
								for key, value of oidcConsent
									if key == 'rp'
										title = value
									if key == 'scope'
										name = value
									if key == 'epoch'
										epoch = value
								subres.push
									title: title
									value: name
									epoch: epoch
									td: "2"
							delete session[attr]
						else if session[attr].toString().match(/\w+/)
							subres.push
								title: attr
								value: session[attr]
								epoch: ''
							delete session[attr]
						else
							delete session[attr]
					else
						delete session[attr]
				if subres.length >0
					res.push
						title: "__#{category}__"
						nodes: subres

			# 3. Add OpenID and notifications already notified
			_insert '^openid', 'OpenID'
			_insert '^notification_(.+)', '__notificationsDone__'

			# 4. Add session history if exists
			if session._loginHistory
				tmp = []
				if session._loginHistory.successLogin
					for l in session._loginHistory.successLogin
						# History custom values
						cv = ""
						for key, value of l
							if !key.match /^(_utime|ipAddr|error)$/ 
								cv += ", #{key} : #{value}"
						tab = cv.split ', '
						tab.sort()
						cv = tab.join ', '
						tmp.push
							t: l._utime
							title: $scope.localeDate l._utime
							value: "Success (IP #{l.ipAddr})" + cv
				if session._loginHistory.failedLogin
					for l in session._loginHistory.failedLogin
						# History custom values
						cv = ""
						for key, value of l
							if !key.match /^(_utime|ipAddr|error)$/
								cv += ", #{key} : #{value}"
						tab = cv.split ', '
						tab.sort()
						cv = tab.join ', '
						tmp.push
							t: l._utime
							title: $scope.localeDate l._utime
							value: "Error #{l.error} (IP #{l.ipAddr})" + cv
				delete session._loginHistory
				tmp.sort (a,b) ->
					b.t - a.t
				res.push
					title: '__loginHistory__'
					nodes: tmp

			# 5. Other keys (attributes and macros)
			tmp = []
			for key, value of session
				tmp.push
					title: key
					value: value
			tmp.sort (a,b) ->
				if a.title > b.title then 1
				else if a.title < b.title then -1
				else 0
			# Sort by real and spoofed attributes
			real = []
			spoof = []
			for element in tmp
				if element.title.match(new RegExp('^' + $scope.impPrefix + '.+$'))
					console.log element, '-> real attribute'
					real.push element
				else
					#console.log element, '-> spoofed attribute'
					spoof.push element
			tmp = spoof.concat real

			res.push
				title: '__attributesAndMacros__'
				nodes: tmp
			return {
				_utime: time
				nodes: res
			}

		$scope.currentScope = scope
		sessionId = scope.$modelValue.session
		$http.get("#{scriptname}sessions/#{sessionType}/#{sessionId}").then (response) ->
			$scope.currentSession = transformSession response.data
			$scope.currentSession.id = sessionId
		$scope.showT = false

	$scope.localeDate = (s) ->
		d = new Date(s * 1000)
		return d.toLocaleString()

	$scope.isValid = (epoch, type) ->
		path = $location.path()
		now = Date.now() / 1000
		console.log "Path", path
		console.log "Session epoch", epoch
		console.log "Current date", now
		console.log "Session TTL", sessionTTL
		isValid = now - epoch < sessionTTL || $location.path().match(/^\/persistent/)
		if type == 'msg'
			console.log "Return msg"
			if isValid then return "info" else return "warning"
		else if type == 'style'
			console.log "Return style"
			if isValid then return {} else return {'color': '#627990', 'font-style': 'italic'}
		else
			console.log "Return isValid"
			return isValid

	$scope.strToLocaleDate = (s) ->
		arrayDate = s.match /^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})$/
		return s unless arrayDate.length
		d = new Date "#{arrayDate[1]}-#{arrayDate[2]}-#{arrayDate[3]}T#{arrayDate[4]}:#{arrayDate[5]}:#{arrayDate[6]}"
		return d.toLocaleString()

	# Function to change interface language
	$scope.getLanguage = (lang) ->
		$scope.lang = lang
		$scope.form = 'white'
		$scope.init()
		$scope.showM = false

	# URI local path management
	pathEvent = (event, next, current) ->
		n = next.match /#!?\/(\w+)/
		sessionType = 'global'
		if n == null
			$scope.type = '_whatToTrace'
		else if n[1].match /^(persistent|offline)$/
			sessionType = RegExp.$1
			$scope.type = '_session_uid'
		else
			$scope.type = n[1]
		$scope.init()

	$scope.$on '$locationChangeSuccess', pathEvent

	# Function to update tree: download value of opened subkey
	autoId = 0
	$scope.updateTree = (value, node, level, over, currentQuery, count) ->
		$scope.waiting = true

		# Query scheme selection:

		#  - if defined above
		scheme = if schemes[$scope.type]
			schemes[$scope.type]

		#  - _updateTime must be displayed as startTime
		else if $scope.type == '_updateTime'
			schemes._startTime

		#  - default to _whatToTrace scheme
		else
			schemes._whatToTrace

		# Build query using schemes
		query = scheme[level] $scope.type, value, currentQuery

		# If number of session exceeds "max" and overScheme exists, call it
		if count > max and overScheme[$scope.type]
			if tmp = overScheme[$scope.type] $scope.type, value, level, over, currentQuery
				over++
				query = tmp
				level = level - 1
			else
				over = 0
		else
			over = 0

		# Launch HTTP query
		$http.get("#{scriptname}sessions/#{sessionType}?#{query}").then (response) ->
			data = response.data
			if data.result
				for n in data.values
					autoId++
					n.id = "node#{autoId}"
					if level < scheme.length - 1
						n.nodes = []
						n.level = level + 1
						n.query = query
						n.over  = over

						# Date display in tree
						if $scope.type.match /^(?:start|update)Time$/
							n.title = n.value
							# 12 digits -> 12:34
							.replace(/^(\d{8})(\d{2})(\d{2})$/,'$2:$3')
							# 11 digits -> 12:30
							.replace(/^(\d{8})(\d{2})(\d)$/,'$2:$30')
							# 10 digits -> 12h
							.replace(/^(\d{8})(\d{2})$/,'$2h')
							#  8 digits -> 2016-03-15
							.replace(/^(\d{4})(\d{2})(\d{2})/,'$1-$2-$3')
					node.push n
				$scope.total = data.total if value == ''
			$scope.waiting = false
		, (resp) ->
			$scope.waiting = false

		# Highlight current selection
		console.log "Selection", sessionType
		$scope.navssoStyle = {color: '#777'}
		$scope.offlineStyle = {color: '#777'}
		$scope.persistentStyle = {color: '#777'}
		$scope.navssoStyle = {color: '#333'} if sessionType == 'global'
		$scope.offlineStyle = {color: '#333'} if sessionType == 'offline'
		$scope.persistentStyle = {color: '#333'} if sessionType == 'persistent'

	# Intialization function
	# Simply set $scope.waiting to false during $translator and tree root
	# initialization
	$scope.init = ->
		$scope.waiting = true
		$scope.data = []
		$scope.currentScope = null
		$scope.currentSession = null
		$q.all [
			$translator.init $scope.lang
			$scope.updateTree '', $scope.data, 0, 0
		]
		.then ->
			$scope.waiting = false
		, (resp) ->
			$scope.waiting = false
		# Colorized link
		$scope.activeModule = "sessions"
		$scope.myStyle = {color: '#ffb84d'}

	# Query scheme initialization
	# Default to '_whatToTrace'
	c = $location.path().match /^\/(\w+)/
	$scope.type = if c then c[1] else '_whatToTrace'
]
