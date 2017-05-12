//=package package_own;
//
//=depends _.fuga;
//=depends _.hoge;
//=import _.fuga.package -> Load;
//=import _.hoge.package -> Ext;

var Test = Class.create({
    initialize:function(name){
        this.name = name:
    }
});
new Test("<TMPL_VAR NAME=text>");
