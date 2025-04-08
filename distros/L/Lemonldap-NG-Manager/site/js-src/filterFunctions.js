var filterFunctions;

filterFunctions = {
  // Here, `node` is the root node (authParams) and `n` points to its
  // conditional subnodes. This subnodes have the property `show` that can
  // be set to true or false depending on what has to be displayed

  authParams: function(scope, $q, node) {
    var i, len, n, ref, wait;
    // 1. be sure to have all datas in main nodes
    wait = [];
    ref = node.nodes;
    for (i = 0, len = ref.length; i < len; i++) {
      n = ref[i];
      wait.push(scope.getKey(n));
    }
    // 2. then do the job
    return $q.all(wait).then(function() {
      var all, j, k, l, len1, len2, len3, len4, len5, len6, m, nToShow, nd, o, p, q, r, ref1, ref2, ref3, ref4, restart, s;
      // Flag to see all nodes
      all = false;
      // Nodes to show
      nToShow = [];
      // Little function to select good node
      p = function(s) {
        var tmp;
        tmp = s.toLowerCase();
        if (tmp === 'openidconnect') {
          tmp = 'oidc';
        }
        nToShow.push(tmp + 'Params');
        if (tmp === 'ad') {
          return nToShow.push('ldapParams');
        }
      };
      ref1 = node.nodes;
      // Show all normal nodes
      for (j = 0, len1 = ref1.length; j < len1; j++) {
        n = ref1[j];
        p(n.data);
      }
      ref2 = node.nodes_cond;
      // Select conditional nodes to show
      for (k = 0, len2 = ref2.length; k < len2; k++) {
        n = ref2[k];
        // Flag to reload this after downloading datas
        restart = 0;
        // Select unopened/opened node
        nd = n._nodes ? n._nodes : n.nodes;
        // Case "Choice"
        if (node.nodes[0].data === 'Choice' && n.id === 'choiceParams') {
          console.log('Choice is selected');
          if (nd[1].cnodes) {
            restart++;
          } else {
            nd = nd[1]._nodes ? nd[1]._nodes : nd[1].nodes;
            for (l = 0, len3 = nd.length; l < len3; l++) {
              m = nd[l];
              ref3 = m.data;
              for (o = 0, len4 = ref3.length; o < len4; o++) {
                s = ref3[o];
                if (typeof s === 'string') {
                  p(s);
                }
              }
            }
          }
        // Case "Combination"
        } else if (node.nodes[0].data === 'Combination' && n.id === 'combinationParams') {
          console.log('Combination is selected');
          if (nd[1].cnodes) {
            restart++;
          } else {
            nd = nd[1]._nodes ? nd[1]._nodes : nd[1].nodes;
            for (q = 0, len5 = nd.length; q < len5; q++) {
              m = nd[q];
              p(m.data.type);
            }
          }
        }
        if (restart) {
          scope.waiting = true;
          scope.download({
            '$modelValue': nd[1]
          }).then(function() {
            return filterFunctions.authParams(scope, $q, node);
          });
          return;
        }
      }
      ref4 = node.nodes_cond;
      for (r = 0, len6 = ref4.length; r < len6; r++) {
        n = ref4[r];
        if (!all && nToShow.indexOf(n.id) === -1) {
          n.show = false;
        } else {
          n.show = true;
        }
      }
    });
  }
};

window.filterFunctions = filterFunctions;
