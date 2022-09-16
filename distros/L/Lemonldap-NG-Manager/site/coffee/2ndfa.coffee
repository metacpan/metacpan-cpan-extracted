###
# 2ndFA Session explorer
###

setMsg = (msg, level) ->
	$('#msg').html window.translate msg
	$('#color').removeClass 'message-positive message-warning alert-success alert-warning'
	$('#color').addClass "message-#{level}"
	level = 'success' if level == 'positive'
	$('#color').addClass "alert-#{level}"

displayError = (j, status, err) ->
	console.log 'Error', err
	res = JSON.parse j.responseText
	if res and res.error
		res = res.error.replace(/.* /, '')
		console.log 'Returned error', res
		setMsg res, 'warning'

# Max number of session to display (see overScheme)
max = 25

# Queries to do each type of display: each array item corresponds to the depth
# of opened nodes in the tree
schemes =
	_whatToTrace: [
		(t,v) ->
			"groupBy=substr(#{t},1)"
		(t,v) ->
			"#{t}=#{v}*"
	]

overScheme =
	_whatToTrace: (t,v,level,over) ->
		console.log 'overSchema => level', level, 'over', over
		if level == 1 and v.length > over
			"#{t}=#{v}*&groupBy=substr(#{t},#{(level+over+1)})"
		else
			null

hiddenAttributes = '_password'

# Attributes to group in session display
categories =
    dateTitle:          ['_utime', '_startTime', '_updateTime']
    sfaTitle:			['_2fDevices']

# Menu entries
menu =
	home: []

###
# AngularJS applications
###
llapp = angular.module 'llngSessionsExplorer', ['ui.tree', 'ui.bootstrap', 'llApp']

# Main controller
llapp.controller 'SessionsExplorerCtrl', ['$scope', '$translator', '$location', '$q', '$http', ($scope, $translator, $location, $q, $http) ->
	$scope.links = links
	$scope.menulinks = menulinks
	$scope.staticPrefix = staticPrefix
	$scope.scriptname = scriptname
	$scope.formPrefix = formPrefix
	$scope.availableLanguages = availableLanguages
	$scope.waiting = true
	$scope.showM = false
	$scope.showT = true
	$scope.data = []
	$scope.currentScope = null
	$scope.currentSession = null
	$scope.menu = menu
	$scope.searchString = ''
	$scope.sfatypes = {}

	# Import translations functions
	$scope.translateP = $translator.translateP
	$scope.translate = $translator.translate
	$scope.translateTitle = (node) ->
		$translator.translateField node, 'title'
	sessionType = 'persistent'

	# Handle menu items
	$scope.menuClick = (button) ->
		if button.popup
			window.open button.popup
		else
			button.action = button.title unless button.action
			switch typeof button.action
				when 'function'
					button.action $scope.currentNode, $scope
					$scope[button.action]()
				when 'string'
					$scope[button.action]()
				else
					console.log typeof button.action
		$scope.showM = false

	## SESSIONS MANAGEMENT
	# Search 2FA sessions
	$scope.search2FA = (clear) ->
		if clear
			$scope.searchString = ''
		$scope.currentSession = null
		$scope.data = []
		$scope.updateTree2 '', $scope.data, 0, 0
	
	# Delete 2FA device
	$scope.delete2FA = (type, epoch) ->
		items = document.querySelectorAll(".data-#{epoch}")
		for e in items
			e.remove()
		$scope.waiting = true
		$http['delete']("#{scriptname}sfa/#{sessionType}/#{$scope.currentSession.id}?type=#{type}&epoch=#{epoch}").then (response) ->
			$scope.waiting = false
		, (resp) ->
			$scope.waiting = false
		$scope.showT = false

	## Add 2FA device
	#$scope.add2FA (type) = ->
		#$scope.waiting = true
		#$http['put']("#{scriptname}sfa/#{sessionType}/#{$scope.currentSession.id}?Key=U2F").then (response) ->
			#$scope.currentSession = null
			#$scope.currentScope.remove()
			#$scope.waiting = false
		#, (resp) ->
			#$scope.currentSession = null
			#$scope.currentScope.remove()
			#$scope.waiting = false
		#$scope.showT = false


	## Verify 2FA device
	#$scope.verify2FA (epoch) = ->
		#$scope.waiting = true
		#$http['post']("#{scriptname}sfa/#{sessionType}/#{$scope.currentSession.id}?Key=TOTP").then (response) ->
			#$scope.currentSession = null
			#$scope.currentScope.remove()
			#$scope.waiting = false
		#, (resp) ->
			#$scope.currentSession = null
			#$scope.currentScope.remove()
			#$scope.waiting = false
		#$scope.showT = true

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
			_stToStr = (s) ->
				s
			_insert = (re, title) ->
				tmp = []
				reg = new RegExp(re)
				for key,value of session
					if key.match(reg) and value
						tmp.push
							title: key
							value: value
						delete session[key]
				if tmp.length > 0
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
							value = _stToStr value
							pattern = /^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})$/
							arrayDate = value.match(pattern)
							session[key] = "#{arrayDate[3]}/#{arrayDate[2]}/#{arrayDate[1]} à #{arrayDate[4]}:#{arrayDate[5]}:#{arrayDate[6]}"
			
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
										sfrow: true
							delete session[attr]
						else if session[attr].toString().match(/\w+/)
							subres.push
								title: attr
								value: session[attr]
							delete session[attr]
						else
							delete session[attr]
					else
						delete session[attr]
				if subres.length >0
					res.push
						title: "__#{category}__"
						nodes: subres
			return {
				_utime: time
				nodes: res
			}

		$scope.currentScope = scope
		sessionId = scope.$modelValue.session
		$http.get("#{scriptname}sfa/#{sessionType}/#{sessionId}").then (response) ->
			$scope.currentSession = transformSession response.data
			$scope.currentSession.id = sessionId
		$scope.showT = false

	$scope.localeDate = (s) ->
		d = new Date(s * 1000)
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
		if n == null or n[1].match /^(persistent)$/
			$scope.type = '_session_uid'
		$scope.init()

	$scope.$on '$locationChangeSuccess', pathEvent

	# Functions to update tree: download value of opened subkey
	autoId = 0
	$scope.updateTree = (value, node, level, over, currentQuery, count) ->
		$scope.waiting = true

		# Query scheme selection:

		#  - if defined above
		scheme = if schemes[$scope.type]
			schemes[$scope.type]

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
		$http.get("#{scriptname}sfa/#{sessionType}?#{query}"+Object.entries($scope.sfatypes).map((x) -> if x[1] then "&type=" + x[0] else "").join("")).then (response) ->
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
						
					node.push n
				$scope.total = data.total if value == ''
			$scope.waiting = false
		, (resp) ->
			$scope.waiting = false
				
	# Functions to filter U2F sessions tree : download value of opened subkey
	$scope.updateTree2 = (value, node, level, over, currentQuery, count) ->
		$scope.waiting = true

		# Query scheme selection:

		#  - if defined above
		scheme = if schemes[$scope.type]
			schemes[$scope.type]

		#  - _updateTime must be displayed as startDate
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

		# Launch HTTP
		$http.get("#{scriptname}sfa/#{sessionType}?_session_uid=#{$scope.searchString}*&groupBy=substr(_session_uid,#{$scope.searchString.length})"+Object.entries($scope.sfatypes).map((x) -> if x[1] then "&type=" + x[0] else "").join("")).then (response) ->
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

					node.push n
				$scope.total = data.total if value == ''
			$scope.waiting = false
		, (resp) ->
			$scope.waiting = false

	# Intialization function
	# Simply set $scope.waiting to false during $translator and tree root
	# initialization
	$scope.init = ->
		$scope.waiting = true
		$scope.data = []
		$q.all [
			$translator.init $scope.lang
			$scope.updateTree '', $scope.data, 0, 0
		]
		.then ->
			$scope.waiting = false
		, (resp) ->
			$scope.waiting = false
		# Colorized link
		$scope.activeModule = "2ndFA"
		$scope.myStyle = {color: '#ffb84d'}

	# Query scheme initialization
	# Default to '_whatToTrace'
	c = $location.path().match /^\/(\w+)/
	$scope.type = if c then c[1] else '_whatToTrace'
	
]



