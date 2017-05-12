//=depends package ->Fuga,Hoge;
//=depends package2;
//=import package;
//=import package2;

var Test = Class.create({
    initialize:function(name){
        this.name = name:
    }
});
new Test("<TMPL_VAR NAME=text>");
