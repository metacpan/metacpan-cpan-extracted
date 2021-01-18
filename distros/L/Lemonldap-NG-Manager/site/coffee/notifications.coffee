###
# LemonLDAP::NG Notifications Explorer client
###

# Max number of notifications to display (see overScheme)
max = 25

scheme = [
	(v) ->
		"groupBy=substr(uid,1)"
	(v) ->
		"uid=#{v}*&groupBy=uid"
	(v) ->
		"uid=#{v}"
]

# When number of children nodes exceeds "max" value
# and does not return "null", a level is added. See
# "$scope.updateTree" method
overScheme =
	(v,level,over) ->
		# "v.length > over" avoids a loop if one user opened more than "max"
		# notifications
		console.log 'overScheme => level', level, 'over', over
		if level == 1 and v.length > over
			"uid=#{v}*&groupBy=substr(uid,#{(level+over+1)})"
		else
			null

# Session menu
menu =
	actives: [
		title: 'markAsDone'
		icon: 'check'
	]
	done: [
		title: 'deleteNotification'
		icon: 'trash'
	]
	new: [
		title: 'save'
		icon: 'save'
	]
	home: []

# AngularJS application
llapp = angular.module 'llngNotificationsExplorer', [ 'ui.tree', 'ui.bootstrap', 'llApp' ]

# Main controller
llapp.controller 'NotificationsExplorerCtrl', [ '$scope', '$translator', '$location', '$q', '$http', '$uibModal', ($scope, $translator, $location, $q, $http, $uibModal) ->
	$scope.links = links
	$scope.menulinks = menulinks
	$scope.staticPrefix = staticPrefix
	$scope.scriptname = scriptname
	$scope.formPrefix = formPrefix
	$scope.availableLanguages = availableLanguages
	$scope.waiting = true
	$scope.showM = false
	$scope.showT = true
	$scope.showForm = false
	$scope.data = []
	$scope.form = {}
	$scope.formPost = {}
	$scope.currentScope = null
	$scope.currentNotification = null
	$scope.menu = menu

	# Import translation functions
	$scope.translateP = $translator.translateP
	$scope.translate = $translator.translate
	$scope.translateTitle = (node) ->
		$translator.translateField node, 'title'

	# Handler menu items
	$scope.menuClick = (button) ->
		if button.popup
			window.open button.popup
		else
			button.action or= button.title
			switch typeof button.action
				when 'function'
					button.action $scope.currentNode, $scope

				when 'string'
					$scope[button.action]()

				else
					console.log typeof button.action
		$scope.showM = false

	# Notification management
	$scope.markAsDone = ->
		$scope.waiting = true
		$http.put("#{scriptname}notifications/#{$scope.type}/#{$scope.currentNotification.uid}_#{$scope.currentNotification.reference}", {done:1}).then (response) ->
			$scope.currentNotification = null
			$scope.currentScope.remove()
			$scope.message =
				title: 'notificationDeleted'
			$scope.showModal "alert.html"
			$scope.waiting = false
			$scope.init()
		, (response) ->
			$scope.message =
				title: 'notificationNotDeleted'
				message: response.statusText
			$scope.showModal "alert.html"
			$scope.waiting = false
			$scope.init()

	$scope.deleteNotification = ->
		$scope.waiting = true
		$http['delete']("#{scriptname}notifications/#{$scope.type}/#{$scope.currentNotification.uid}_#{$scope.currentNotification.reference}_#{$scope.currentNotification.done}").then (response) ->
			$scope.currentNotification = null
			$scope.currentScope.remove()
			$scope.message =
				title: 'notificationPurged'
			$scope.showModal "alert.html"
			$scope.waiting = false
			$scope.init()
		, (response) ->
			$scope.message =
				title: 'notificationNotPurged'
				message: response.statusText
			$scope.showModal "alert.html"
			$scope.waiting = false
			$scope.init()

	# Open node
	$scope.stoggle = (scope) ->
		node = scope.$modelValue
		if node.nodes.length == 0
			$scope.updateTree node.value, node.nodes, node.level, node.over, node.query, node.count
		scope.toggle()

	$scope.notifDate = (s) ->
		if s?
			if s.match /(\d{4})-(\d{2})-(\d{2})/
				s = s.substr(0, 4) + s.substr(5, 2) + s.substr(8, 2)
			d = new Date(s.substr(0, 4), s.substr(4, 2) - 1, s.substr(6, 2))
			return d.toLocaleDateString()
		return ''

	$scope.getLanguage = (lang) ->
		$scope.lang = lang
		if $scope.form.date
			$scope.form.date = new Date()
		else
			$scope.form = 'white'
		$scope.init()
		$scope.showM = false

	$scope.$on '$locationChangeSuccess', (event, next, current) ->
		n = next.match /#!?\/(\w+)/
		$scope.type = if n? then n[1] else 'actives'
		if $scope.type == 'new'
			$scope.displayCreateForm()
		else
			$scope.showForm = false
			$scope.init()

	autoId = 0
	$scope.updateTree = (value, node, level, over, currentQuery, count) ->
		$scope.waiting = true
		query = scheme[level] value, currentQuery

		# If number of notifications exceeds "max", call it
		if count > max
			if tmp = overScheme value, level, over
				over++
				query = tmp
				level = level - 1
			else
				over = 0
		else
			over = 0

		# Launch HTTP query
		if $scope.type == 'done' || $scope.type == 'actives'
			$http.get("#{scriptname}notifications/#{$scope.type}?#{query}").then (response) ->
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

		# Highlight current selection
		console.log "Selection", $scope.type
		$scope.activesStyle = {color: '#777'}
		$scope.doneStyle = {color: '#777'}
		$scope.newStyle = {color: '#777'}
		$scope.activesStyle = {color: '#333'} if $scope.type == 'actives'
		$scope.doneStyle = {color: '#333'} if $scope.type == 'done'		

	$scope.displayNotification = (scope) ->
		$scope.waiting = true
		$scope.currentScope = scope
		node = scope.$modelValue
		notificationId = node.notification.replace(/#/g, '_')
		if $scope.type == 'actives'
			notificationId = "#{node.uid}_#{node.reference}"
		$http.get("#{scriptname}notifications/#{$scope.type}/#{notificationId}").then (response) ->
			$scope.currentNotification =
				uid: node.uid
				reference: node.reference
				condition: node.condition
			if $scope.type == 'done'
				$scope.currentNotification.done = response.data.done
			try 
				console.log "Try to parse a JSON formated notification..."
				notif = JSON.parse response.data.notifications
				$scope.currentNotification.date = $scope.notifDate(notif.date)
				$scope.currentNotification.text = notif.text
				$scope.currentNotification.title = notif.title
				$scope.currentNotification.subtitle = notif.subtitle
				$scope.currentNotification.check = notif.check
			catch e
				console.log "Unable to parse JSON"
				$scope.currentNotification.notifications = response.data.notifications	
			$scope.waiting = false
		, (resp) ->
			$scope.waiting = false
		$scope.showT = false

	# Modal launcher
	$scope.showModal = (tpl, init) ->
		modalInstance = $uibModal.open
			templateUrl: tpl
			controller: 'ModalInstanceCtrl'
			size: 'lg'
			resolve:
				elem: ->
					(s) ->
						$scope[s]
				set: ->
					(f,s) ->
						$scope[f] = s
				init: ->
					init
		d = $q.defer()
		modalInstance.result.then (msgok) ->
			$scope.message =
				title: ''
				message: ''
			d.resolve msgok
		, (msgnok) ->
			$scope.message =
				title: ''
				message: ''
			d.reject msgnok

	$scope.save = ->
		if $scope.form.uid and $scope.form.reference and $scope.form.xml
			$scope.waiting = true
			$scope.formPost.uid = $scope.form.uid
			if $scope.form.date
				$scope.formPost.date = dateToString($scope.form.date)
			$scope.formPost.reference = $scope.form.reference
			$scope.formPost.condition = $scope.form.condition
			$scope.formPost.xml = $scope.form.xml
			$http.post('notifications/actives', $scope.formPost).then (response) ->
				data = response.data
				$scope.form = {}
				if data.result == 1
					$scope.message =
						title: 'notificationCreated'
				else
					$scope.message =
						title: 'notificationNotCreated'
						message: data.error
				$scope.showModal "alert.html"
				$scope.waiting = false
				$scope.form.date = new Date()
			, (response) ->
				$scope.message =
					title: 'notificationNotCreated'
					message: response.statusText
				$scope.showModal "alert.html"
				$scope.waiting = false
				$scope.form.date = new Date()
		else
			$scope.message =
				title: 'incompleteForm'
			$scope.showModal "alert.html"
		$scope.form.date = new Date()

	$scope.init = ->
		$scope.waiting = true
		$scope.showM = false
		$scope.showT = false
		$scope.data = []
		$scope.currentScope = null
		$scope.currentNotification = null
		$q.all [
			$translator.init $scope.lang
			$scope.updateTree '', $scope.data, 0, 0
		]
		.then ->
			$scope.waiting = false
		, (resp) ->
			$scope.waiting = false
		# Colorized link
		$scope.activeModule = "notifications"
		$scope.myStyle = {color: '#ffb84d'}

	$scope.displayCreateForm = ->
		$scope.activesStyle = {color: '#777'}
		$scope.doneStyle = {color: '#777'}
		$scope.newStyle = {color: '#333'}
		$scope.waiting = true
		$translator.init($scope.lang).then ->
			$scope.currentNotification = null
			$scope.showForm = true
			$scope.data = []
			$scope.waiting = false
			$scope.form.date = new Date()

	c = $location.path().match /^\/(\w+)/
	$scope.type = if c then c[1] else 'actives'

	# Datepicker
	$scope.popupopen = ->
		$scope.popup.opened = true

	$scope.dateOptions =
		startingDay: 1
		minDate : new Date()

	$scope.popup =
		opened: false

	# Date conversion
	dateToString = (dt) ->
		year = dt.getFullYear()
		month = dt.getMonth() + 1
		if month < 10
			month = "0#{month}"
		day = dt.getDate()
		if day < 10
			day = "0#{day}"
		return "#{year}-#{month}-#{day}"
]
