var filterFunctions = {
  'authParams': function(scope, $q, node) {
    /* Here, `node` is the root node (authParams) and `n` points to its
     * conditional subnodes. This subnodes have the property `show` that can
     * be set to true or false depending on what has to be displayed
     */

    /* 1. be sure to have all datas in main nodes */
    var wait = [];
    node.nodes.forEach(function(n) {
      wait.push(scope.getKey(n));
    });
    /* 2. then do the job */
    $q.all(wait).then(function() {
      /* 2.1. Get all modules needed */
      var all = false;
      var nToShow = [];
      var p = function(s) {
        var tmp = s.toLowerCase();
        if (tmp == 'ad') {
          tmp = 'ldap';
        }
        if (tmp == 'openidconnect') {
          tmp = 'oidc';
        }
        nToShow.push(tmp + 'Params');
      }
      if (node.nodes[0].data.match(/^(Choice|Multi)/)) {
        node.nodes[1].data = node.nodes[0].data;
        if (node.nodes[0].data.match(/^Choice/)) {
          node.nodes[2].data = 'Choice';
        }
        //all = true;
      }
      node.nodes.forEach(function(n) {
        p(n.data);
      });
      /* Get choice or multi sub modules */
      node.nodes_cond.forEach(function(n) {
        if (node.nodes[0].data == 'Choice' && n.id == 'choiceParams') {
          var nd = n._nodes ? n._nodes : n.nodes;
          if (!nd[1].cnodes) {
            nd = nd[1]._nodes ? nd[1]._nodes : nd[1].nodes;
            nd.forEach(function(m) {
              m.data.forEach(function(s) {
                p(s);
              });
            });
          }
          else {
            scope.waiting = true;
            scope.download({
              '$modelValue': nd[1]
            }).then(function() {
              filterFunctions.authParams(scope, $q, node)
            });
            return;
          };
        }
        else if (node.nodes[0].data == 'Multi' && n.id == 'multiParams') {
          var nd = n._nodes ? n._nodes : n.nodes;
          if (! ('data' in nd[0])) {
            $q.all([scope.getKey(nd[0]), scope.getKey(nd[1])]).then(function() {
              filterFunctions.authParams(scope, $q, node)
            });
            return;
          }
          /* TODO: Change this with multiValueSeparator when it will be set in tree */
          var sep = ';';
          var reg = new RegExp(sep + '\\s*(\\w+)', 'g');
          var s = '' + (nd[0].data ? sep + nd[0].data : '') + (nd[1].data ? sep + nd[1].data : '');
          while ((result = reg.exec(s)) !== null) {
            p(result[1]);
          }
        }
      });
      /* 2.2 Display modules */
      node.nodes_cond.forEach(function(n) {
        if (!all && nToShow.indexOf(n.id) == -1) {
          n.show = false
        } else {
          n.show = true;
        }
      });
    });
  }
}