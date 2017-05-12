(function() {

var t = new Test.Chicken();

t.plan(1);

t.test_template(
    '<div><div id="cats"><ul class="list"><li class="item"><span class="name">...</span></li></ul></div></div>',
    {
        '#cats' : new Chicken.Hierarchy ({
            list_selector : '.list',
            item_selector : '.item',
            values       : {
                node     : { '.name' : "Twinkles"  },
                children : [
                    { node : { '.name' : "Shnuckums" } },
                    { 
                        node     : { '.name' : "Bilbo" },
                        children : [
                            { 
                                node     : { '.name' : "Dweezil" },
                                children : [
                                    { node : { '.name' : "Tabby" } },                      
                                ]
                            },
                            { node : { '.name' : "Abraxas"    } },                                                
                        ]
                    },
                ]
            }
        })
    },
    '<div id="cats"><ul class="list"><li class="item"><span class="name">Twinkles</span><ul class="list"><li class="item"><span class="name">Shnuckums</span></li><li class="item"><span class="name">Bilbo</span><ul class="list"><li class="item"><span class="name">Dweezil</span><ul class="list"><li class="item"><span class="name">Tabby</span></li></ul></li><li class="item"><span class="name">Abraxas</span></li></ul></li></ul></li></ul></div>',
    '... simple hierarchy'
);

})();