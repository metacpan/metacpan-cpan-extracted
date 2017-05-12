//=depends package;
//=depends package2;
//=import package  -> Test1,Test2;
//=import package2 -> Test1:Test21,Test2:Test22;
//=import package3 -> *;

var Test = Class.create({
    initialize:function(name){
        this.name = name:
    }
});
new Test("<TMPL_VAR NAME=text>");
