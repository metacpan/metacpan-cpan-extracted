
Example Code for using Embperl::Forms and the wizard.pl application
===================================================================

On Unix you can access this example using

   make start

and then accessing

   http://localhost:8531/eg/forms/wizard/action.epl

Continue with step 6



On Windows this example assumes that Embperl is extracted under 

    C:\perl\msrc\embperl

and Apache is installed at

    C:\Programme\Apache Software Foundation\Apache2.2

In this example Embperl is installed on Windows and uses Apache as CGI script.

The same should also work with mod_perl and Unix. You only have to modify
the httpd.conf accordingly.

The example assumes the Perl is already install and available in your PATH.


1.) First of all install Embperl

cd C:\perl\msrc\embperl
perl Makefile.PL

-> Answer all question with 'N' (because we don't use mod_perl in this example)

nmake
nmake install


2.) Copy CGI Script to Apache directory


copy epocgi.pl "C:\Programme\Apache Software Foundation\Apache2.2\cgi-bin"
copy embpcgi.pl "C:\Programme\Apache Software Foundation\Apache2.2\cgi-bin"



3.) Modify the configuration file

It is located at


C:\Programme\Apache Software Foundation\Apache2.2\conf\httpd.conf

At the end add the following directives:

# ----------------------------

AddType text/html .epl
AddType text/html .ehtml


Alias /forms c:/perl/msrc/embperl/eg/forms

SetEnv PERL5LIB c:/perl/msrc/embperl/eg/forms

SetEnv EMBPERL_OBJECT_ADDPATH  c:/perl/msrc/embperl/eg/forms/lib
SetEnv EMBPERL_SESSION_HANDLER_CLASS no
# optAllFormData + optRawInput
SetEnv EMBPERL_OPTIONS 0x2010


<Location /forms/pages>
    Order allow,deny
    Allow from all
    
    Action text/html /cgi-bin/embpcgi.pl
    Options             ExecCGI
</Location>


<Location /forms/wizard>
    Order allow,deny
    Allow from all

    Action text/html /cgi-bin/epocgi.pl

    Options ExecCGI
    SetEnv Embperl_Appname setupwizard
    SetEnv Embperl_Object_Base base.epl
    SetEnv Embperl_Object_App  wizard.pl

</Location>

# ----------------------------



4.) Start Apache on the command line

cd C:\Programme\Apache Software Foundation\Apache2.2

bin\httpd


-> Apache will write it's logfiles in C:\Programme\Apache Software Foundation\Apache2.2\logs

5.) Call a simple page

Per default Apache listens on Port 8080 on Windows, in case you have installed
it on a different port please change the followings URLs accordingly. 
Open the following URL in a browser:

    http://localhost:8080/forms/pages/loop.htm


This shows the environemnt of the CGI script. This is a very simple Embperl page.


6.) Calls the wizard

Open

    http://localhost:8080/forms/wizard/action.epl

This will show you a wizard where you can enter setup information. The wizard will
ask page by page what is necssary. It will ask different things depending on your input.

For example you can choose different ways to get to the internet and it will ask the
access data (can call different pages internaly) depending on your choise.

If you choose "import" on the first page, you get an form that modifies itself dynamicly
depending on what type you chosse at the top of the page.



7.) The files

Here is an overview of all files underneath the eg/forms directory:



- eg\forms/Embperl:

Directory for modules of the Embperl::MyForm namespace which are used to customize 
the forms and add addtional controls

* MyForm.pm

This defines the Embperl::MyForm Object which overwrites some methods to tell
Embperl::Form where to located additional objects.


- eg\forms/Embperl/MyForm/Control:

Directory for Custom controls

- eg\forms/Embperl/MyForm/DataSource:

Directory for custom datasource objects. Datasource object are used to fill
select or radio controls, as far as they don't have static data in the form 
definition itself. Use the datasrc => attribute to specify a datasource object.

The example comes with two datasource
objects. These two only return static data, but datasource objects can return 
any data for example from a database.

* languages.pm
* netmask.pm

- eg\forms/css:
* EmbperlForm.css

Stylesheets

- eg\forms/js:
* EmbperlForm.js
* prototype.js

Necessary JavaScript code

- eg\forms/lib:

Generaly code

* footer.epl

This file is included in every page at the bottom. It is called from base.epl

* header.epl

This file is included in every page at the top. It is called from base.epl

* wizard.epl

This file contains the HTML layout for the wizard. It contains several methods
which can be overwritten in the page objects to customize the layout.

* wizard.pl

Thie is the controller object of the wizard. It controls the workflow.

- eg\forms/pages:
* loop.htm

Simpley Embperl page as example

- eg\forms/wizard:

This directory contains the actual pages of the wizard and it's configuration

* base.epl

This file defines the HTML layout of the page in which ths wizard is embedded.

* wizconfig.pl

This file contains the configuration of the wizard.

The method "getpages" must return an array ref of all page files that are
used by the wizard.

The method "init" is called on every request and can be used for initialization
purposes.

Every of the remaining files in the directory define a page for the wizard:

action.epl
do.epl
dsl.epl
exportslave.epl
finish.epl
gateway.epl
importslave.epl
inetconnect.epl
isdn.epl
name.epl
network.epl
organisation.epl

Every page contains four methods:

- title: 

Is used to specify the title of the page

- condition:

The page is only displayed if the method return true, otherwise it is skipped

- show:

This method contains the code and HTML which is actually shown for the page,
including the form elements.

- verify:

This method is called after the user has pressed Next. If it is used to verify
the user input. If the input is ok, it should return true, othwise it should 
return 0 and set $fdat{-msg} to the error message.



8.) Inclunding forms

A form is defined by a fields definition which is passed to the showfields method.

A fields definition consists of a set of controls. Each control has a set of 
attributes.

Available controls can be found at embperl/Embperl/Form/Control

Each control contains a description of the possible attributes.

Some controls (like select, selectdyn, radio, checkboxes) can get it's input
from a datasource control (see above). In the example code most of the datasrc
attributes are renamed to xdatasrc because the datasource object are not 
included in the example code.

Each control definition can also contain a validation rule. See Embperl::Form::Validate
for more informaion on validation rules.

