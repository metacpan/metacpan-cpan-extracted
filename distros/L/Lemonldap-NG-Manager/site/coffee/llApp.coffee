###
LemonLDAP::NG base app module

 This file contains:
  - 3 AngularJS directives (HTML attributes):
	* `on-read-file` to get file content
	* `resizer` to resize HTML div
	* `trspan` to set translated message in HTML content
  - a AngularJS factory to handle 401 Ajax responses
###

llapp = angular.module 'llApp', ['ngAria']

# TRANSLATION SYSTEM
#
# It provides:
#  - 3 functions to translate:
#    * translate(word)
#    * translateP(paragraph): only __words__ are translated
#    * translateField(object, property)
#  - an HTML attribute called 'trspan'. Example: <h3 trspan="portal"/>

# $translator provider

llapp.provider '$translator', ->
	res = {}
	# Language detection
	c = decodeURIComponent(document.cookie)
	if c.match /llnglanguage=(\w+)/
		res.lang = RegExp.$1
	else if navigator
		langs = []
		langs2 = []
		nlangs = [ navigator.language ]
		if navigator.languages
			nlangs = navigator.languages
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
		res.lang = if langs[0] then langs[0] else if langs2[0] then langs2[0] else 'en'
	else
		res.lang = 'en'
	console.log 'Selected lang ->', res.lang

	# Internal properties
	res.deferredTr = []
	res.translationFields = {}

	# Translation methods
	#  1. word translation
	res.translate = (s) ->
		if res.translationFields[s]
			s = res.translationFields[s]
		return s

	#  2. node field translation
	res.translateField = (node, field) ->
		res.translate node[field]

	#  3. paragraph translation (verify that json is available
	res.translateP = (s) ->
		if s and res.translationFields.portal
			s = s.replace /__(\w+)__/g, (match,w) ->
				res.translate w
		s

	# Initialization
	this.$get = [ '$q', '$http', ($q, $http) ->
		res.last = ''
		res.init = (lang) ->
			lang = res.lang unless lang
			d = new Date()
			d.setTime d.getTime() + 30*86400000
			document.cookie = "llnglanguage=#{lang}; expires=#{d.toUTCString()}; path=/"
			d = $q.defer()
			if res.last != lang
				res.last = lang
				$http.get("#{window.staticPrefix}languages/#{lang}.json").then (response) ->
					res.translationFields = response.data
					for h in res.deferredTr
						h.e[h.f] res.translationFields[h.m]
					res.deferredTr = []
					d.resolve "Translation files loaded"
				, (response) ->
					d.reject ''
			else
				d.resolve "No change"
			d.promise
		res
	]
	this

# Translation directive (HTML trspan tag)
llapp.directive 'trspan', [ '$translator', ($translator) ->
	restrict: 'A'
	replace: false
	transclude: true
	scope:
		trspan: "@"
	link: (scope, elem, attr) ->
		if $translator.translationFields.portal
			attr.trspan = $translator.translate(attr.trspan)
		# Deferred translations will be done after JSON download
		else
			$translator.deferredTr.push
				e: elem
				f: 'text'
				m: attr.trspan
		elem.text attr.trspan
	template: ''
]

# Form menu management
#
# Two parts:
#  - $htmlParams: used to store values inserted as <script type="text/menu">.
#                 It provides menu() method to get them
#  - HTML "script" element handler
llapp.provider '$htmlParams', ->
	this.$get = ->
		params = {}
		set: (key, obj) ->
			params[key] = obj
		menu: ->
			params.menu
		# To be used later
		params: ->
			params.params
	this

llapp.directive 'script', ['$htmlParams', ($htmlParams) ->
	restrict: 'E'
	terminal: true
	compile: (element, attr) ->
		if attr.type and t = attr.type.match /text\/(menu|parameters)/
			try
				return $htmlParams.set t[1], JSON.parse(element[0].text)
			catch e
				console.log "Parsing error:", e
				return
]

# Modal controller used to display messages

llapp.controller 'ModalInstanceCtrl', ['$scope', '$uibModalInstance', 'elem', 'set', 'init', ($scope, $uibModalInstance, elem, set, init) ->
	oldvalue = null
	$scope.elem = elem
	$scope.set = set
	$scope.result = init
	$scope.staticPrefix = window.staticPrefix
	currentNode = elem 'currentNode'
	$scope.translateP = elem 'translateP'
	if currentNode
		oldValue = currentNode.data
		$scope.currentNode = currentNode

	$scope.ok = ->
		set('result', $scope.result)
		$uibModalInstance.close(true)

	$scope.cancel = ->
		if currentNode then $scope.currentNode.data = oldValue
		$uibModalInstance.dismiss('cancel')

	# test if value is in select
	$scope.inSelect = (value) ->
		for i in $scope.currentNode.select
			if i.k == value then return true
		return false
]

# File reader directive
#
# Add "onReadFile" HTML attribute to be used in a "file" input
# The content off attribute will be launched.
#
# Example:
# <input type="file" on-read-file="replaceContent($fileContent)"/>

llapp.directive 'onReadFile', [ '$parse', ($parse) ->
	restrict: 'A'
	scope: false
	link: (scope, element, attrs) ->
		fn = $parse attrs.onReadFile
		element.on 'change', (onChangeEvent) ->
			reader = new FileReader()
			reader.onload = (onLoadEvent) ->
				scope.$apply () ->
					fn scope,
						$fileContent: onLoadEvent.target.result
			reader.readAsText ((onChangeEvent.srcElement || onChangeEvent.target).files[0])
]

# Resize system
#
# Add a "resizer" HTML attribute
llapp.directive 'resizer', ['$document', ($document) ->
	hsize = null
	rsize = null
	($scope, $element, $attrs) ->
		$element.on 'mousedown', (event) ->
			if $attrs.resizer == 'vertical'
				rsize = $($attrs.resizerRight).width() + $($attrs.resizerLeft).width()
			else
				hsize = $($attrs.resizerTop).height() + $($attrs.resizerBottom).height()
			event.preventDefault()
			$document.on 'mousemove', mousemove
			$document.on 'mouseup', mouseup
		mousemove = (event) ->
			# Handle vertical resizer
			if $attrs.resizer == 'vertical'
				x = event.pageX
				if $attrs.resizerMax and x > $attrs.resizerMax
					x = parseInt $attrs.resizerMax
				$($attrs.resizerLeft).css
					width: "#{x}px"
				$($attrs.resizerRight).css
					width: "#{rsize-x}px"
			# Handle horizontal resizer
			else
				y = event.pageY - $('#navbar').height()
				$($attrs.resizerTop).css
					height: "#{y}px"
				$($attrs.resizerBottom).css
					height: "#{hsize-y}px"
		mouseup = () ->
			$document.unbind 'mousemove', mousemove
			$document.unbind 'mouseup', mouseup
]

###
# Authentication system
#
# If a 401 code is returned and if "Authorization" header contains an url,
# user is redirected to this url (but target is replaced by location.href
###
llapp.factory '$lmhttp', ['$q', '$location', ($q, $location) ->
	responseError: (rejection) ->
		if rejection.status == 401 and window.portal
			window.location = "#{window.portal}?url=" + window.btoa(window.location).replace(/\//, '_')
		else
			return $q.reject rejection
]

llapp.config [ '$httpProvider', ($httpProvider) ->
	$httpProvider.interceptors.push '$lmhttp'
]
