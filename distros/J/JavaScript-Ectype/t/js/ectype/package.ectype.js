//=package package;
var Test = Class.create({
    initialize:function(name){
        this.name = name;
    }
});
new Test("<TMPL_VAR NAME=text>");
