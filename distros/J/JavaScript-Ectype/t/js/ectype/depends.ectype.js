//=depends package;
//=depends package2;

var Test = Class.create({
    initialize:function(name){
        this.name = name;
    }
});
new Test("<TMPL_VAR NAME=text>");
