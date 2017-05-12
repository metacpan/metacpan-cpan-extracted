/* Dezi::Admin::UI JavaScript */


Ext.Loader.setConfig({enabled: true});

Ext.Loader.setPath({
    'Ext.ux': ExtJS_URL + '/examples/ux/',
    'Ext.app': ExtJS_URL + '/examples/portal/classes/'
});
Ext.require([
    'Ext.grid.*',
    'Ext.data.*',
    'Ext.util.*',
    'Ext.grid.PagingScroller',
    'Ext.ux.form.SearchField',
    'Ext.Viewport',
    'Ext.tip.QuickTipManager',
    'Ext.tab.Panel',
    'Ext.ux.GroupTabPanel',
    'Ext.app.PortalColumn',
    'Ext.app.PortalDropZone',
    'Ext.app.Portlet',
    'Ext.app.GridPortlet',
    'Ext.app.PortalPanel',
    'Ext.fx.target.Sprite'
]);

// create our namespaces
Ext.ns('Dezi.Admin');
Ext.ns('Dezi.Admin.Stats');
Ext.ns('Dezi.Admin.Index');

Ext.define('Dezi.Admin.Stats.Model', {
    extend: 'Ext.data.Model',
    fields: [],  // in http response
    idProperty: 'id'
});

Ext.define('Dezi.Admin.Stats.TermModel', {
    extend: 'Ext.data.Model',
    fields: [],  // in http response
    idProperty: 'term'
});

Ext.define('Dezi.Admin.Index.Model', {
    extend: 'Ext.data.Model',
    fields: [],  // in http response
    idProperty: 'path'
});

// json viewer based on http://jsonviewer.stack.hu/jsonviewer.js

Dezi.Admin.json2leaf = function (json) {
    var ret = [];
    for (var i in json) {
        if (json.hasOwnProperty(i)) {
            if (json[i] === null) {
                ret.push({text: i + ' : null', leaf: true});
            } 
            else if (typeof json[i] === 'string') {
                ret.push({text: i + ' : "' + json[i] + '"', leaf: true});
            } 
            else if (typeof json[i] === 'number') {
                ret.push({text: i + ' : ' + json[i], leaf: true});
            } 
            else if (typeof json[i] === 'boolean') {
                ret.push({text: i + ' : ' + (json[i] ? 'true' : 'false'), leaf: true});
            } 
            else if (typeof json[i] === 'object') {
                ret.push({text: i, children: Dezi.Admin.json2leaf(json[i])});
            } 
            else if (typeof json[i] === 'function') {
                ret.push({text: i + ' : function', leaf: true});
            }
        }
    }
    return ret;
};

Dezi.Admin.StoreToTree = function(json) {
    // convert json from store syntax to tree syntax
    var treeData = [];
    Ext.iterate(json.results, function(invindex, idx, array) {
        //console.log(invindex);
        var thisIdx = {
            text: invindex.path,
            expanded: true,
            children: Dezi.Admin.json2leaf(invindex.config)
        };
        
        treeData.push(thisIdx);
    });

    return treeData;
};

Dezi.Admin.Index.createViewer = function(json) {

    var treeData = Dezi.Admin.StoreToTree(json);

    var propertyGrid = Ext.create('Ext.grid.property.Grid', {
        region: 'east',
        width: 300,
        border: true,
        //split: true,
        listeners: {
            beforeedit: function () {
                return false;
            },
            render : function() {
                console.log('propertygrid render');
            }
        },
        source: {},
        selModel: {
            mode: 'SIMPLE',
        }
    });
        
    //console.log('defined propertygrid');
    
    var treeStore = Ext.create('Ext.data.TreeStore', {
        root: {
            text: 'Indexes',
            expanded: true,
            children: treeData
        }
    });
    
    var gridbuilder = function(node) {
        //console.log(node);
        if (node.isLeaf()) {
            node = node.parentNode;
        }
        // occur, that are not yet particularly
        if (!node.childNodes.length) {
            node.expand(false, false);
            node.collapse(false, false);
        }
        var source = {};
        for (var i = 0; i < node.childNodes.length; i++) {
            //console.log(node.childNodes[i]);
            var t = node.childNodes[i].raw.text.indexOf(':');
            if (t === -1) {
                source[node.childNodes[i].raw.text] = '...';
            } else {
                source[node.childNodes[i].raw.text.substring(0, t)] = node.childNodes[i].raw.text.substring(t + 1);
            }
        }
        propertyGrid.setSource(source);
    };
    
    var tree = Ext.create('Ext.tree.Panel', {
        minWidth: 100,
        region: 'center',
        lines: true, 
        store: treeStore,
        border: true,
        autoScroll: true,
        //trackMouseOver: false,
        listeners: {
            render: function (tree) {
                //console.log('render tree', tree);
                tree.getSelectionModel().on('selectionchange', function (selModel, nodes) {
                    //console.log(selModel,nodes);
                    gridbuilder(nodes[0]);
                });
            },
            contextmenu: function (node, e) {
                console.log('contextmenu');
                var menu = new Ext.menu.Menu({
                    items: [{
                        text: 'Expand',
                        handler: function () {
                            node.expand();
                        }
                    }, {
                        text: 'Expand all',
                        handler: function () {
                            node.expand(true);
                        }
                    }, '-', {
                        text: 'Collapse',
                        handler: function () {
                            node.collapse();
                        }
                    }, {
                        text: 'Collapse all',
                        handler: function () {
                            node.collapse(true);
                        }
                    }]
                });
                menu.showAt(e.getXY());
            }
        }
    });
    
    var panel = Ext.create('Ext.panel.Panel', {
        layout: 'border',
        height: 400,
        border: false,
        items: [tree, propertyGrid]
    
    });
     
    //return tree; 
    return panel;

}

Dezi.Admin.Stats.TimesChart = function() {
    var search_path = '*/search';
    if (Ext.isDefined(DEZI_ABOUT.search)) {
        search_path = DEZI_ABOUT.search.replace(DEZI_ABOUT.api_base_url,'*');
    }
    var statsStore = Ext.create('Ext.data.Store', {
        model: 'Dezi.Admin.Stats.Model',
        proxy: {
            type: 'ajax',
            url: DEZI_ADMIN_BASE_URL + '/api/stats',
            extraParams: {
                sort:   'tstamp',
                dir:    'DESC',
                q:      'path:'+search_path,
                limit:  100
            },
            reader: {
                type: 'json'
            }  
        },
        remoteFilter: true,
        // fetch most recent, display oldest to newest left to right
        sorters: [
            { property: 'tstamp', direction: 'ASC' }
        ],
        listeners: {
            load: function(store, records, successful, eOpts) {
                // TODO transform records??
                //console.log('loaded: ', records);
                
            },
            metachange: function(store,meta,eOpts) {
                //console.log('meta changed to: ', meta);
                
            }
        
        
        },

        autoLoad: true
    });
    
    var chart = Ext.create('Ext.chart.Chart', {
        xtype: 'chart',
        border: false,
        animate: true,
        store: statsStore,
        insetPadding: 30,
        legend: {
            position: 'right'  
        },
        axes: [{
            type: 'Numeric',
            minimum: 0,
            decimals: 4,            
            position: 'left',
            fields: ['build_time','search_time'],
            title: 'Seconds',
            width: 10,
            grid: true,
            label: {
                renderer: Ext.util.Format.numberRenderer('0.00'),
                font: '10px Arial'
            }
        }, {
            type: 'Category',  // TODO Time
            position: 'bottom',
            fields: ['tstamp'],
            title: 'Request time',
            grid: true,
            label: {
                font: '9px Arial',
                renderer: Ext.util.Format.dateRenderer('Y-m-d H:i:s'),
                rotate: {
                    degrees: 270
                }
            }
        }],
        series: [
          {
            type: 'column',
            axis: 'left',
            xField: 'tstamp',
            yField: ['build_time','search_time'],
            tips: {
                trackMouse: true,
                width: 150,
                height: 60,
                renderer: function(storeItem, item) {
                    //console.log(item);
                    this.setTitle(item.yField+' ('+storeItem.get(item.yField)+")<br/>"+storeItem.get('total')+" hits for<br/>"+storeItem.get('q'));
                }
            }
          }
        ]
    });

    return chart;
}
    
Ext.define('Dezi.Admin.Stats.List', {
    extend: 'Ext.grid.Panel',
    alias: 'widget.dezi-admin-stats-list',
    
    onStoreSizeChange: function () {
        //console.log(this);
        Ext.getCmp('dezi-admin-stats-list').down('#status').update({count: this.getTotalCount()});
    },
    
    initComponent: function() {

        // create the Data Store
        Dezi.Admin.Stats.store = Ext.create('Ext.data.Store', {
            
            model: 'Dezi.Admin.Stats.Model',
        
            // allow the grid to interact with the paging scroller by buffering
            buffered: true,
        
            // server-side sorting
            remoteSort: true,
        
            // sql limit
            pageSize: 50,

            // how many rows to keep in buffer
            leadingBufferZone: 200,
            proxy: {
                type: 'ajax',
                url: DEZI_ADMIN_BASE_URL + '/api/stats',
                reader: {
                    type: 'json'
                },
                // sends single sort as multi parameter
                simpleSortMode: true,
            
                simpleGroupMode: false,
            
                // Parameter name to send filtering information in
                filterParam: 'q'
            
            },
            listeners: {
                totalcountchange: this.onStoreSizeChange
            },
            remoteFilter: true,

            autoLoad: true
        });
                    
        //console.log('store ok');

        Ext.apply(this, {
           //width: 700,
           //height: 500,
           collapsible: false,
           title: 'Stats Grid',
           store: Dezi.Admin.Stats.store,
           loadMask: true,
           dockedItems: [{
               dock: 'top',
               xtype: 'toolbar',
               items: [{
                   width: 400,
                   fieldLabel: 'Search',
                   labelWidth: 50,
                   xtype: 'searchfield',
                   store: Dezi.Admin.Stats.store
               }, '->', {
                   xtype: 'component',
                   itemId: 'status',
                   tpl: 'Matching records: {count}',
                   style: 'margin-right:5px'
               }]
           }],
           selModel: {
               pruneRemoved: false
           },
           multiSelect: false,
           viewConfig: {
               trackOver: false
           },
           
           // grid columns
           columns:[{
               xtype: 'rownumberer',
               width: 50,
               sortable: false
           },
           {
               text: "Path",
               dataIndex: 'path',
               flex: 1,
               sortable: true
           },
           {
               text: "Remote User",
               dataIndex: 'remote_user',
               width: 100,
               sortable: true
           },
           {
               text: "Query",
               dataIndex: 'q',
               flex: 1,
               sortable: true
           },
           {
               text: "Build time",
               dataIndex: 'build_time',
               width: 60,
               sortable: true
           },
           {
               text: "Search time",
               dataIndex: 'search_time',
               width: 60,
               sortable: true
           },
           {
               text: "Total",
               dataIndex: 'total',
               width: 50,
               sortable: true
           },
           {
               text: "When",
               dataIndex: 'tstamp',
               width: 120,
               renderer: Ext.util.Format.dateRenderer('n/j/Y g:i A'),
               sortable: true
           }]
        });
     
        this.callParent(arguments);  
    }
    
});

Dezi.Admin.UI = function() {

    Ext.tip.QuickTipManager.init();

    // create some portlet tools using built in Ext tool ids
    var tools = [{
        type: 'gear',
        handler: function () {
            Ext.Msg.alert('Message', 'The Settings tool was clicked.');
        }
    }, {
        type: 'close',
        handler: function (e, target, panel) {
            panel.ownerCt.remove(panel, true);
        }
    }];
    
    var performance_chart = Dezi.Admin.Stats.TimesChart();
    
    var today = new Date();
    var ms_in_day = 24*3600*1000; // 86400000;
    
    var term30Store = Ext.create('Ext.data.Store', {
        
        model: 'Dezi.Admin.Stats.TermModel',
            
        // client-side sorting
        remoteSort: false,
    
        // sql limit. make it large because response is aggregate
        pageSize: 1000,

        proxy: {
            type: 'ajax',
            url: DEZI_ADMIN_BASE_URL + '/api/stats/terms',
            reader: {
                type: 'json'
            },
            
            extraParams: {
                q : 'tstamp >= ' + ((today.getTime() - (30 * ms_in_day))/1000)
            },
            
            // sends single sort as multi parameter
            simpleSortMode: true,
        
            simpleGroupMode: false,
        
            // Parameter name to send filtering information in
            filterParam: 'q'
        
        },
        
        remoteFilter: true,

        autoLoad: true
    });
    
    var term30Grid = Ext.create('Ext.grid.Panel', {
        height:250,
        title:'Last 30 days',
        store: term30Store,
        
        columns: [{
            text: 'Term',
            flex: 50,
            dataIndex: 'term'
        },{
            text: 'Count',
            flex: 20,
            dataIndex: 'count'
        },{
            text: 'Most Recent',
            flex: 30,
            dataIndex: 'recent',
            renderer: Ext.util.Format.dateRenderer('n/j/Y g:i A')
        }],
        
        bbar: [
            {
                text: 'Reload',
                //iconCls: 'refresh',
                handler: function() {
                    term30Store.load();
                }
            }
        ]
    });
    
    var term7Store = Ext.create('Ext.data.Store', {
        
        model: 'Dezi.Admin.Stats.TermModel',
            
        // client-side sorting
        remoteSort: false,
    
        // sql limit. make it large because response is aggregate
        pageSize: 1000,

        proxy: {
            type: 'ajax',
            url: DEZI_ADMIN_BASE_URL + '/api/stats/terms',
            reader: {
                type: 'json'
            },
            
            extraParams: {
                q : 'tstamp >= ' + ((today.getTime() - (7 * ms_in_day))/1000)
            },
            
            // sends single sort as multi parameter
            simpleSortMode: true,
        
            simpleGroupMode: false,
        
            // Parameter name to send filtering information in
            filterParam: 'q'
        
        },
        
        remoteFilter: true,

        autoLoad: true
    });
    
    var term7Grid = Ext.create('Ext.grid.Panel', {
        height:250,
        title:'Last 7 days',
        store: term7Store,
        
        columns: [{
            text: 'Term',
            flex: 50,
            dataIndex: 'term'
        },{
            text: 'Count',
            flex: 20,
            dataIndex: 'count'
        },{
            text: 'Most Recent',
            flex: 30,
            dataIndex: 'recent',
            renderer: Ext.util.Format.dateRenderer('n/j/Y g:i A')
        }],
        
        bbar: [
            {
                text: 'Reload',
                //iconCls: 'refresh',
                handler: function() {
                    term7Store.load();
                }
            }
        ]
    });

    Ext.create('Ext.Viewport', {
        layout: 'fit',
        items: [{
            xtype: 'grouptabpanel',
            activeGroup: 0,
            items: [
            {
                mainItem: 1,
                items: [{
                    //title: 'Stat Details',
                    iconCls: 'x-icon-stats',
                    tabTip: 'Stat details tabtip',
                    //border: false,
                    id: 'dezi-admin-stats-list',
                    xtype: 'dezi-admin-stats-list',
                    margin: '10',
                    height: null
                }, 
                {
                    xtype: 'portalpanel',
                    title: 'Dashboard',
                    tabTip: 'Dashboard tabtip',
                    border: false,
                    items: [{
                        flex: 1,
                        items: [
                            {
                                title: 'Dezi Server Administration',
                                border: false,
                                html: '<div class="portlet-content">' + 'Welcome to Dezi::Admin.' + '</div>'
                            },
                            {
                                title: 'Top Terms',
                                border: false,
                                layout: 'fit',
                                items: [{
                                    xtype: 'tabpanel',
                                    activeTab: 0,
                                    items: [
                                        term7Grid,
                                        term30Grid
                                    ]
                                }]
                            },
                            {
                                height: 500,
                                title: 'Performance',
                                layout: 'fit',
                                items: performance_chart,
                                border: true
                                //tbar: [
                                    // TODO start/end date range picker. slider?
                                //]
                            }
                        ]
                    }]
                }
                /*, 
                {
                    title: 'Subscriptions',
                    iconCls: 'x-icon-subscriptions',
                    tabTip: 'Subscriptions tabtip',
                    style: 'padding: 10px;',
                    border: false,
                    layout: 'fit',
                    items: [{
                        xtype: 'tabpanel',
                        activeTab: 1,
                        items: [{
                            title: 'Nested Tabs',
                            html: 'nested tab content'
                        }]
                    }]
                }, {
                    title: 'Users',
                    iconCls: 'x-icon-users',
                    tabTip: 'Users tabtip',
                    style: 'padding: 10px;',
                    html: 'user content'
                }
                */
                ]
            }, 
            {
                expanded: true,
                items: [
                {
                    title: 'Configuration',
                    iconCls: 'x-icon-configuration',
                    tabTip: 'Configuration tabtip',
                    style: 'padding: 10px;',
                    border: false,
                    html: 'Dezi server configration not yet available. The Indexes menu option reveals index metadata.'
                }, 
                {
                    title: 'Indexes',
                    iconCls: 'x-icon-templates',
                    tabTip: 'Indexes tabtip',
                    style: 'padding: 10px;',
                    border: false,
                    autoScroll: true,
                    listeners: {
                        activate: function() {
                            //console.log('indexes', this);
                            var tab = this;
                            Ext.Ajax.request({
                                url: DEZI_ADMIN_BASE_URL + '/api/indexes',
                                success: function(response) {
                                    var json = Ext.decode(response.responseText);
                                    var panel = Dezi.Admin.Index.createViewer(json);
                                    tab.removeAll();
                                    tab.add(panel);
                                }
                            });
                        }
                    
                    }
                }
                ]
            }, 
/*
            {
                expanded: false,
                items: {
                    title: 'TODO ',
                    bodyPadding: 10,
                    html: '<h1>TODO</h1>',
                    border: false
                }
            }
*/
            ]
        }]
    });
    
};

// render whole page
Ext.onReady(function () {

    if (Ext.getBody().id === "ui") {
        Dezi.Admin.UI();
    }

});
