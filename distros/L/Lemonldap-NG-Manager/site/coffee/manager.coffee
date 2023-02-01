###
LemonLDAP::NG Manager client

This is the main app file. Other are:
 - struct.json and js/confTree.js that contains the full tree
 - translate.json that contains the keywords translation

This file contains:
 - the AngularJS controller
###

llapp = angular.module 'llngManager', ['ui.tree', 'ui.bootstrap', 'llApp', 'ngCookies']

###
Main AngularJS controller
###

llapp.controller 'TreeCtrl', [
	'$scope', '$http', '$location', '$q', '$uibModal', '$translator', '$cookies', '$htmlParams',
	($scope, $http, $location, $q, $uibModal, $translator, $cookies, $htmlParams) ->
		$scope.links = window.links
		$scope.menu = $htmlParams.menu
		$scope.menulinks = window.menulinks
		$scope.staticPrefix = window.staticPrefix
		$scope.formPrefix = window.formPrefix
		$scope.availableLanguages = window.availableLanguages
		$scope.waiting = true
		$scope.showM = false
		$scope.showT = false
		$scope.form = 'home'
		$scope.currentCfg = {}
		$scope.confPrefix = window.confPrefix
		$scope.message = {}
		$scope.result = ''

		# Import translations functions
		$scope.translateTitle = (node) ->
			return $translator.translateField node, 'title'
		$scope.translateP = $translator.translateP
		$scope.translate = $translator.translate

		# HELP DISPLAY
		$scope.helpUrl = 'start.html#configuration'
		$scope.setShowHelp = (val) ->
			val = !$scope.showH unless val?
			$scope.showH = val
			d = new Date(Date.now())
			d.setFullYear(d.getFullYear() + 1)
			$cookies.put 'showhelp', (if val then 'true' else 'false'), {"expires": d}
		$scope.showH = if $cookies.get('showhelp') == 'false' then false else true
		$scope.setShowHelp(true) unless $scope.showH?

		# INTERCEPT AJAX ERRORS
		readError = (response) ->
			e = response.status
			j = response.statusLine
			$scope.waiting = false
			if e == 403
				$scope.message =
					title: 'forbidden'
					message: ''
					items: []
			else if e == 401
				console.log 'Authentication needed'
				$scope.message =
					title: 'authenticationNeeded'
					message: '__waitOrF5__'
					items: []
			else if e == 400
				$scope.message =
					title: 'badRequest'
					message: j
					items: []
			else if e > 0
				$scope.message =
					title: 'badRequest'
					message: j
					items: []
			else
				$scope.message =
					title: 'networkProblem'
					message: ''
					items: []
			return $scope.showModal 'message.html'

		# Modal launcher
		$scope.showModal = (tpl, init) ->
			modalInstance = $uibModal.open
				templateUrl: tpl
				controller: 'ModalInstanceCtrl'
				size: 'lg'
				resolve:
					elem: ->
						return (s) ->
							return $scope[s]
					set: ->
						return (f, s) ->
							$scope[f] = s
					init: ->
						return init
			d = $q.defer()
			modalInstance.result.then (msgok) ->
				$scope.message =
					title: ''
					message: ''
					items: []
				d.resolve msgok
			,(msgnok) ->
				$scope.message =
					title: ''
					message: ''
					items: []
				d.reject msgnok
			return d.promise

		# FORM DISPLAY FUNCTIONS

		# Function called when a menu item is selected. It launch function stored in
		# "action" or "title"
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

		# Display main form
		$scope.home = ->
			$scope.form = 'home'
			$scope.showM = false

		# SAVE FUNCTIONS

		# Private method called by $scope.save()
		_checkSaveResponse = (data) ->
			$scope.message =
				title: ''
				message: ''
				items: []
				itemsE:[]
				itemsNC: []
				itemsW: []
			$scope.confirmNeeded = true if data.needConfirm
			$scope.message.message = data.message if data.message
			# Sort messages
			if data.details
				for m of data.details when m != '__changes__'
					if m == '__needConfirmation__'
						$scope.message.itemsNC.push
							message: m
							items: data.details[m]
						console.log 'NeedConfirmation:', $scope.message.itemsNC
					else if m == '__warnings__'
						$scope.message.itemsW.push
							message: m
							items: data.details[m]
						console.log 'Warnings:', $scope.message.itemsW
					else
						$scope.message.itemsE.push
							message: m
							items: data.details[m]
						console.log 'Errors:', $scope.message.itemsE
				$scope.message.items =  $scope.message.itemsE.concat $scope.message.itemsNC.concat $scope.message.itemsW
			$scope.waiting = false
			if data.result == 1
				# Force reloading page
				$location.path '/confs/'
				$scope.message.title = 'successfullySaved'
			else
				$scope.message.title = 'saveReport'
			$scope.showModal 'message.html'

		# Download raw conf
		$scope.downloadConf = () ->
			window.open $scope.confPrefix + $scope.currentCfg.cfgNum + '?full=1'

		# Main save function
		$scope.save = ->
			$scope.showModal('save.html').then ->
				$scope.waiting = true
				$scope.data.push
					id: "cfgLog"
					title: "cfgLog"
					data: if $scope.result then $scope.result else ''
				$http.post("#{window.confPrefix}?cfgNum=#{$scope.currentCfg.cfgNum}&cfgDate=#{$scope.currentCfg.cfgDate}#{if $scope.forceSave then "&force=1" else ''}", $scope.data).then (response) ->
					$scope.data.pop()
					_checkSaveResponse response.data
				,(response) ->
					readError response
					$scope.data.pop()
			, ->
				console.log 'Saving canceled'
			$scope.showM = false

		# Raw save function
		$scope.saveRawConf = ($fileContent) ->
			$scope.waiting = true
			$http.post("#{window.confPrefix}/raw", $fileContent).then (response) ->
				_checkSaveResponse(response.data)
			, readError

		# Restore raw conffunction
		$scope.restore = ->
			$scope.currentNode = null
			$scope.form = 'restore'

		# Cancel save function
		$scope.cancel = ->
			$scope.currentNode.data = null
			$scope.getKey($scope.currentNode)

		# NODES MANAGEMENT
		idinc = 1
		$scope._findContainer = ->
			return $scope._findScopeContainer().$modelValue
		$scope._findScopeContainer = ->
			cs = $scope.currentScope
			while not cs.$modelValue.type.match(/Container$/)
				cs = cs.$parentNodeScope
			return cs
		$scope._findScopeByKey = (k) ->
			cs = $scope.currentScope
			while not (cs.$modelValue.title == k)
				cs = cs.$parentNodeScope
			return cs

		# Add grant rule entry
		$scope.newGrantRule = ->
			node = $scope._findContainer()
			l = node.nodes.length
			n = if l > 0 then l - 1 else 0
			node.nodes.push
				id: "#{node.id}/n#{idinc++}"
				title: 'New rule'
				re: 'Message'
				comment: 'New rule'
				data: '1'
				type: "grant"

		# Add rules entry
		$scope.newRule = ->
			node = $scope._findContainer()
			l = node.nodes.length
			n = if l > 0 then l - 1 else 0
			node.nodes.splice n, 0,
				id: "#{node.id}/n#{idinc++}"
				title: 'New rule'
				re: '^/new'
				comment: 'New rule'
				data: 'accept'
				type: "rule"

		# Add form replay
		$scope.newPost = ->
			node = $scope._findContainer()
			node.nodes.push
				id: "#{node.id}/n#{idinc++}"
				title: "/absolute/path/to/form"
				data: {}
				type: "post"

		$scope.newPostVar = ->
			$scope.currentNode.data.vars = [] unless $scope.currentNode.data.vars?
			$scope.currentNode.data.vars.push ['var1', '$uid']

		# Add auth chain entry to authChoice
		$scope.newAuthChoice = ->
			node = $scope._findContainer()
			node.nodes.push
				id: "#{node.id}/n#{idinc++}"
				title: "1_Key"
				data: ['Null', 'Null', 'Null']
				type: "authChoice"
			$scope.execFilters $scope._findScopeByKey 'authParams'

		# Add hash entry
		$scope.newHashEntry = ->
			node = $scope._findContainer()
			node.nodes.push
				id: "#{node.id}/n#{idinc++}"
				title: 'new'
				data: ''
				type: "keyText"

		# Menu cat entry
		$scope.newCat = ->
			cs = $scope.currentScope
			if cs.$modelValue.type == 'menuApp'
				cs = cs.$parentNodeScope
			cs.$modelValue.nodes.push
				id: "#{cs.$modelValue.id}/n#{idinc++}"
				title: "New category"
				type: "menuCat"
				nodes: []

		# Menu app entry
		$scope.newApp = ->
			cs = $scope.currentScope
			if cs.$modelValue.type == 'menuApp'
				cs = cs.$parentNodeScope
			cs.$modelValue.nodes.push
				id: "#{cs.$modelValue.id}/n#{idinc++}"
				title: "New application"
				type: "menuApp"
				data:
					description: "New app description"
					uri: "https://test.example.com/"
					tooltip: "New app tooltip"
					logo: "network.png"
					display: "auto"

		# Combination module
		$scope.newCmbMod = ->
			node = $scope._findContainer()
			node.nodes.push
				id: "#{node.id}/n#{idinc++}"
				title: 'new'
				type: 'cmbModule'
				data:
					type: 'LDAP'
					for: '0'
					over: []
			$scope.execFilters $scope._findScopeByKey 'authParams'

		$scope.newSfExtra = ->
			node = $scope._findContainer()
			node.nodes.push
				id: "#{node.id}/n#{idinc++}"
				title: 'new'
				type: 'sfExtra'
				data:
					type: ''
					rule: ''
					logo: ''
					level: ''
					label: ''
					over: []


		$scope.newSfOver = ->
			d = $scope.currentNode.data
			d.over = [] unless d.over
			d.over.push ["new#{idinc++}", '']

		$scope.newCmbOver = ->
			d = $scope.currentNode.data
			d.over = [] unless d.over
			d.over.push ["new#{idinc++}", '']

		$scope.newChoiceOver = ->
			d = $scope.currentNode.data
			console.log "data", d
			d[5] = [] unless d[5]
			d[5].push ["new#{idinc++}", '']

		# Add host
		$scope.addHost = () ->
			cn = $scope.currentNode
			cn.data=[] unless cn.data
			cn.data.push
				k: "newHost"
				h: [{"k":"key","v":"uid"}]

		# SAML attribute entry
		$scope.addSamlAttribute = ->
			node = $scope._findContainer()
			node.nodes.push
				id: "#{node.id}/n#{idinc++}"
				title: 'new'
				type: 'samlAttribute'
				data: ['0', 'New', '', '']

		# OIDC attribute entry
		$scope.addOidcAttribute = ->
			node = $scope._findContainer()
			node.nodes.push
				id: "#{node.id}/n#{idinc++}"
				title: 'new'
				type: 'oidcAttribute'
				data: ['', 'string', 'auto']

		# Nodes with template
		$scope.addVhost = ->
			name = if $scope.domain then ".#{$scope.domain.data}" else '.example.com'
			$scope.message =
				title: 'virtualHostName'
				field: 'hostname'
			$scope.showModal('prompt.html', name).then ->
				n= $scope.result
				if n
					$scope.addTemplateNode n, 'virtualHost'

		$scope.duplicateVhost = ->
			name = if $scope.domain then ".#{$scope.domain.data}" else '.example.com'
			$scope.message =
				title: 'virtualHostName',
				field: 'hostname'
			$scope.showModal('prompt.html', name).then ->
				n = $scope.result
				return $scope.duplicateNode n, 'virtualHost', $scope.currentNode.title

		$scope.addSamlIDP = ->
			$scope.newTemplateNode 'samlIDPMetaDataNode', 'samlPartnerName', 'idp-example'

		$scope.addSamlSP = ->
			$scope.newTemplateNode 'samlSPMetaDataNode', 'samlPartnerName', 'sp-example'

		$scope.addOidcOp = ->
			$scope.newTemplateNode 'oidcOPMetaDataNode', 'oidcOPName', 'op-example'

		$scope.addOidcRp = ->
			$scope.newTemplateNode 'oidcRPMetaDataNode', 'oidcRPName', 'rp-example'

		$scope.addCasSrv = ->
			$scope.newTemplateNode 'casSrvMetaDataNode', 'casPartnerName', 'srv-example'

		$scope.addCasApp = ->
			$scope.newTemplateNode 'casAppMetaDataNode', 'casPartnerName', 'app-example'

		$scope.newTemplateNode = (type, title, init) ->
			$scope.message =
				title: title
				field: 'name'
			$scope.showModal('prompt.html', init).then ->
				name = $scope.result
				if (name)
					$scope.addTemplateNode name, type

		$scope.addTemplateNode = (name, type) ->
			cs = $scope.currentScope
			while cs.$modelValue.title != "#{type}s"
				cs = cs.$parentNodeScope
			t =
				id: "#{type}s/new__#{name}"
				title: name
				type: type
				nodes: templates type, "new__#{name}"
			setDefault t.nodes
			cs.$modelValue.nodes.push t
			cs.expand()
			return t

		setDefault = (node) ->
			for n in node
				if n.cnodes and n.default
					delete n.cnodes
					n._nodes = n.default
				if n._nodes
					setDefault n._nodes
				else if n.default or n.default == 0
					n.data = n.default
			node

		_getAll = (node) ->
			d = $q.defer()
			d2 = $q.defer()
			if node._nodes
				_stoggle node
				d.resolve()
			else if node.cnodes
				_download(node).then ->
					d.resolve()
			else if node.nodes or node.data
				d.resolve()
			else
				$scope.getKey(node).then ->
					d.resolve()
			d.promise.then ->
				t = []
				if node.nodes
					for n in node.nodes
						t.push _getAll(n)
				$q.all(t).then ->
					d2.resolve()
			return d2.promise

		$scope.duplicateNode = (name, type, idkey) ->
			cs = $scope.currentScope
			_getAll($scope.currentNode).then ->
				while cs.$modelValue.title != "#{type}s"
					cs = cs.$parentNodeScope
				t = JSON.parse JSON.stringify($scope.currentNode).replace(/[*]/g, '').replace(new RegExp(idkey, 'g'), 'new__' + name)
				t.id = "#{type}s/new__#{name}"
				t.title = name
				cs.$modelValue.nodes.push(t)
				return t

		$scope.del = (a, i) ->
			a.splice(i, 1)

		$scope.deleteEntry = ->
			p = $scope.currentScope.$parentNodeScope
			$scope.currentScope.remove()
			$scope.displayForm p

		$scope.down = ->
			id = $scope.currentNode.id
			p = $scope.currentScope.$parentNodeScope.$modelValue
			ind = p.nodes.length
			for n, i in p.nodes
				if n.id == id then ind = i
			if ind < p.nodes.length - 1
				tmp = p.nodes[ind]
				p.nodes[ind] = p.nodes[ind + 1]
				p.nodes[ind + 1] = tmp
			ind

		$scope.up = ->
			id = $scope.currentNode.id
			p = $scope.currentScope.$parentNodeScope.$modelValue
			ind = -1
			for n, i in p.nodes
				if n.id == id then ind = i
			if ind > 0
				tmp = p.nodes[ind]
				p.nodes[ind] = p.nodes[ind - 1]
				p.nodes[ind - 1] = tmp
			ind

		# test if value is in select
		$scope.inSelect = (value) ->
			for n in $scope.currentNode.select
				return true if n.k == value
			return false

		# This is for rule form: title = comment if defined, else title = re
		$scope.changeRuleTitle = (node) ->
			node.title = if node.comment.length > 0 then node.comment else node.re

		# Node opening

		# authParams mechanism: show used auth modules only (launched by stoggle)
		$scope.filters = {}
		$scope.execFilters = (scope) ->
			scope = if scope then scope else $scope
			for filter,func of $scope.filters
				if $scope.filters.hasOwnProperty(filter)
					return window.filterFunctions[filter](scope, $q, func)
			false

		# To avoid binding all the tree, nodes are pushed in DOM only when opened
		$scope.stoggle = (scope) ->
			node = scope.$modelValue
			_stoggle node
			scope.toggle()
		_stoggle = (node) ->
			for n in ['nodes', 'nodes_cond']
				if node["_#{n}"]
					node[n] = []
					for a in node["_#{n}"]
						node[n].push a
					delete node["_#{n}"]
			# Call execFilter for authParams
			if node._nodes_filter
				if node.nodes
					for n in node.nodes
						n.onChange = $scope.execFilters
				$scope.filters[node._nodes_filter] = node
				$scope.execFilters()

		# Simple toggle management
		$scope.toggle = (scope) ->
			scope.toggle()

		# cnodes management: hash keys/values are loaded when parent node is opened
		$scope.download = (scope) ->
			node = scope.$modelValue
			return _download(node)
		_download = (node) ->
			d = $q.defer()
			d.notify 'Trying to get datas'
			$scope.waiting = true
			console.log "Trying to get key #{node.cnodes}"
			uri = encodeURI node.cnodes
			$http.get("#{window.confPrefix}#{$scope.currentCfg.cfgNum}/#{uri}").then (response) ->
				data = response.data
				# Manage datas errors
				if not data
					d.reject 'Empty response from server'
				else if data.error
					if data.error.match(/setDefault$/)
						if node['default']
							node.nodes = node['default'].slice(0)
						else
							node.nodes = []
						delete node.cnodes
						d.resolve 'Set data to default value'
					else
						d.reject "Server return an error: #{data.error}"
				else
					# Store datas
					delete node.cnodes
					if not node.type
						node.type = 'keyTextContainer'
					node.nodes = []
					# TODO: try/catch
					for a in data
						if a.template
							a._nodes = templates a.template, a.title
						node.nodes.push a
						if a.type.match /^rule$/
							console.log "Parse rule AuthnLevel as integer"
							if a.level and typeof a.level == 'string'
								a.level = parseInt(a.level, 10)
					d.resolve 'OK'
				$scope.waiting = false
			, (response) ->
				readError response
				d.reject ''
			return d.promise

		$scope.openCnode = (scope) ->
			$scope.download(scope).then ->
				scope.toggle()

		setHelp = (scope) ->
			while !scope.$modelValue.help and scope.$parentNodeScope
				scope = scope.$parentNodeScope
			$scope.helpUrl = scope.$modelValue.help || 'start.html#configuration'

		# Form management
		#
		# `currentNode` contains the last select node
		#
		# method `diplayForm()`:
		#	- set the `form` property to the name of the form to download
		#		(`text` by default or `home` for node without `type` property)
		#	- launch getKeys to set `node.data`
		#	- hide tree when in XS size
		#
		$scope.displayForm = (scope) ->
			node = scope.$modelValue
			if node.cnodes
				$scope.download scope
			if node._nodes
				$scope.stoggle scope
			$scope.currentNode = node
			$scope.currentScope = scope
			f = if node.type then node.type else 'text'
			if node.nodes || node._nodes || node.cnodes
				$scope.form = if f != 'text' then f else 'mini'
			else
				$scope.form = f
				# Get datas
				$scope.getKey node
			if node.type and node.type == 'simpleInputContainer'
				for n in node.nodes
					$scope.getKey(n)
			$scope.showT = false
			setHelp scope

		$scope.keyWritable = (scope) ->
			node = scope.$modelValue
			# regexp-assemble of:
			#  authChoice
			#  cmbModule
			#  keyText
			#  menuApp
			#  menuCat
			#  rule
			#  oidcAttribute
			#  samlAttribute
			#  samlIDPMetaDataNode
			#  samlSPMetaDataNode
			#  sfExtra
			#  virtualHost
			return if node.type and node.type.match /^(?:s(?:aml(?:(?:ID|S)PMetaDataNod|Attribut)e|fExtra)|oidcAttribute|(?:(?:cmbMod|r)ul|authChoic)e|(?:virtualHos|keyTex)t|menu(?:App|Cat))$/ then true else false

		# Send test Email
		$scope.sendTestMail = ->
			$scope.message =
				title: 'sendTestMail'
				field: 'dest'
			$scope.showModal('prompt.html').then ->
				n= $scope.result
				$scope.waiting = true
				dest = $scope.result
				$http.post("#{window.confPrefix}/sendTestMail", {"dest": dest}).then (response) ->
					success = response.data.success
					error = response.data.error
					$scope.waiting = false
					if success
						$scope.message =
							title: 'ok'
							message: '__sendTestMailSuccess__'
							items: []
					else
						$scope.message =
							title: 'error'
							message: error
							items: []
					
					$scope.showModal 'message.html'
				, readError
			, ->
				console.log('Error sending test email')

		# RSA keys generation
		$scope.newCertificate = ->
			$scope.showModal('password.html').then ->
				$scope.waiting = true
				currentNode = $scope.currentNode
				password = $scope.result
				$http.post("#{window.confPrefix}/newCertificate", {"password": password}).then (response) ->
					currentNode.data[0].data = response.data.private
					currentNode.data[1].data = password
					currentNode.data[2].data = response.data.public
					$scope.waiting = false
				, readError
			, ->
				console.log('New key cancelled')

		$scope.newCertificateNoPassword = ->
			$scope.waiting = true
			currentNode = $scope.currentNode
			$http.post("#{window.confPrefix}/newCertificate", {"password": ''}).then (response) ->
				currentNode.data[0].data = response.data.private
				currentNode.data[1].data = response.data.public
				currentNode.data[2].data = response.data.hash
				$scope.waiting = false
			, readError

		$scope.newRSAKey = ->
			$scope.showModal('password.html').then ->
				$scope.waiting = true
				currentNode = $scope.currentNode
				password = $scope.result
				$http.post("#{window.confPrefix}/newRSAKey", {"password": password}).then (response) ->
					currentNode.data[0].data = response.data.private
					currentNode.data[1].data = password
					currentNode.data[2].data = response.data.public
					$scope.waiting = false
				, readError
			, ->
				console.log('New key cancelled')

		# - return a promise with the data:
		# 	- from node when set
		# 	- after downloading else
		#
		$scope.getKey = (node) ->
			d = $q.defer()
			if !node.data
				$scope.waiting = true
				if node.get and typeof(node.get) == 'object'
					node.data = []
					tmp = []
					for n, i in node.get
						node.data[i] =
							title: n
							id: n
						tmp.push $scope.getKey(node.data[i])
					$q.all(tmp).then ->
						d.resolve(node.data)
					,(response) ->
						d.reject response.statusLine
						$scope.waiting = false
				else
					uri = ''
					if node.get
						console.log "Trying to get key #{node.get}"
						uri = encodeURI node.get
					else
						console.log "Trying to get title #{node.title}"
					$http.get("#{window.confPrefix}#{$scope.currentCfg.cfgNum}/#{if node.get then uri else node.title}").then (response) ->
						# Set default value if response is null or if asked by server
						data = response.data
						if (data.value == null or (data.error and data.error.match /setDefault$/ ) ) and node['default'] != null
							node.data = node['default']
						else
							node.data = data.value
						# Cast int as int (remember that booleans are int for Perl)
						if node.type and node.type.match /^(bool|trool|boolOrExpr)$/
							if typeof node.data == 'string' and node.data.match /^(?:-1|0|1)$/
								node.data = parseInt(node.data, 10)
						if node.type and node.type.match /^int$/
							node.data = parseInt(node.data, 10)
						if node.type and node.type.match /^select$/
							node.data = node.data.toString()
						# Split SAML types
						else if node.type and node.type.match(/^(saml(Service|Assertion)|blackWhiteList)$/) and not (typeof node.data == 'object')
							node.data = node.data.split ';'
						$scope.waiting = false
						d.resolve node.data
					, (response) ->
						readError response
						d.reject response.status
			else
				d.resolve node.data
			return d.promise

		# function `pathEvent(event, next; current)`:
		# Called when $location.path() change, launch getCfg() with the new
		# configuration number
		pathEvent = (event, next, current) ->
			n = next.match(new RegExp('#!?/confs/(latest|[0-9]+)'))
			if n == null
				$location.path '/confs/latest'
			else
				console.log "Trying to get cfg number #{n[1]}"
				$scope.getCfg n[1]
		$scope.$on '$locationChangeSuccess', pathEvent

		# function `getCfg(n)`:
		# Download configuration metadatas
		$scope.getCfg = (n) ->
			if $scope.currentCfg.cfgNum != n
				$http.get("#{window.confPrefix}#{n}").then (response) ->
					$scope.currentCfg = response.data
					d = new Date $scope.currentCfg.cfgDate * 1000
					$scope.currentCfg.date = d.toLocaleString()
					console.log "Metadatas of cfg #{n} loaded"
					$location.path "/confs/#{n}"
					$scope.init()
				, (response) ->
					readError(response).then ->
						$scope.currentCfg.cfgNum = 0
						$scope.init()
			else
				$scope.waiting = false

		# method `getLanguage(lang)`
		# Launch init() after setting current language
		$scope.getLanguage = (lang) ->
			$scope.lang = lang
			# Force reload home
			$scope.form = 'white'
			$scope.init()
			$scope.showM = false

		# Initialization

		# Load JSON files:
		#	- struct.json: the main tree
		#	- languages/<lang>.json: the chosen language datas
		$scope.init = ->
			tmp = null
			$scope.waiting = true
			$scope.data = []
			$scope.confirmNeeded = false
			$scope.forceSave = false
			$q.all [
				$translator.init($scope.lang),
				$http.get("#{window.staticPrefix}struct.json").then (response) ->
					tmp = response.data
					console.log("Structure loaded")
			]
			.then ->
				console.log("Starting structure binding")
				$scope.data = tmp
				tmp = null
				if $scope.currentCfg.cfgNum != 0
					setScopeVars $scope
				else
					$scope.message =
						title: 'emptyConf'
						message: '__zeroConfExplanations__'
					$scope.showModal 'message.html'
				$scope.form = 'home'
				$scope.waiting = false
			, readError
			# Colorized link
			$scope.activeModule = "conf"
			$scope.myStyle = {color: '#ffb84d'}
					
		c = $location.path().match(new RegExp('^/confs/(latest|[0-9]+)'))
		unless c
			console.log "Redirecting to /confs/latest"
			$location.path '/confs/latest'

		# File form function
		$scope.replaceContentByUrl = (node, url) ->
			$scope.waiting = true
			$http.post(window.scriptname + "prx", {url: url}).then (response) ->
				node.data = response.data.content
				$scope.waiting = false
			, readError
		$scope.replaceContent = (node, $fileContent) ->
			node.data = $fileContent

		# Import Filesaver.js saveAs()
		$scope.saveAs = (content, type, filename) ->
			saveAs(new Blob([content], {"type": type}), filename)

		# Save as pem, text,...
		$scope.saveAsPem = (cs,scope) ->
			scope.saveAs "#{cs.data[0].data}\n#{cs.data[2].data}", 'application/x-pem-file', "#{cs.title}.pem"
		$scope.saveAsText = (cs,scope) ->
			scope.saveAs cs.data, 'text/plain', "#{cs.title}.txt"
]
