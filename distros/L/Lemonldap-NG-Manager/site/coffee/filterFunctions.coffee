filterFunctions =
    # Here, `node` is the root node (authParams) and `n` points to its
    # conditional subnodes. This subnodes have the property `show` that can
    # be set to true or false depending on what has to be displayed
    #
	authParams: (scope, $q, node) ->
		# 1. be sure to have all datas in main nodes
		wait = []
		for n in node.nodes
			wait.push scope.getKey n

		# 2. then do the job
		$q.all wait
		.then () ->
			# Flag to see all nodes
			all = false
			# Nodes to show
			nToShow = []

			# Little function to select good node
			p = (s) ->
				tmp = s.toLowerCase()
				if tmp == 'openidconnect'
					tmp = 'oidc'
				nToShow.push tmp + 'Params'
				if tmp == 'ad'
					nToShow.push 'ldapParams'

			# Show all normal nodes
			for n in node.nodes
				p n.data
			# Select conditional nodes to show
			for n in node.nodes_cond
				# Flag to reload this after downloading datas
				restart = 0
				# Select unopened/opened node
				nd = if n._nodes then n._nodes else n.nodes

				# Case "Choice"
				if node.nodes[0].data == 'Choice' and n.id == 'choiceParams'
					console.log 'Choice is selected'
					if nd[1].cnodes
						restart++
					else
						nd = if nd[1]._nodes then nd[1]._nodes else nd[1].nodes
						for m in nd
							for s in m.data
								p s if typeof s == 'string'

				# Case "Combination"
				else if node.nodes[0].data == 'Combination' and n.id == 'combinationParams'
					console.log 'Combination is selected'
					if nd[1].cnodes
						restart++
					else
						nd = if nd[1]._nodes then nd[1]._nodes else nd[1].nodes
						for m in nd
							p m.data.type
				if restart
					scope.waiting = true
					scope.download
						'$modelValue': nd[1]
					.then () ->
						filterFunctions.authParams scope, $q, node
					return
			for n in node.nodes_cond
				if not all and nToShow.indexOf(n.id) == -1
					n.show = false
				else
					n.show = true
			return

window.filterFunctions = filterFunctions
