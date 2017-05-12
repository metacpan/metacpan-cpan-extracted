Hi Ferenc Bodon
========================
 
I install your program ftree:  

1. I copy it to github: https://github.com/mishin/ftree  
------------------------

2. I use xampp XAMPP for Windows 5.6.12 (https://www.apachefriends.org/ru/download.html) to install and configure Apache  
------------------------
I could not install mod_perl on Ubuntu 14.14 (because of Unable to locate package libapache2-mod-perl2 - bad old repository issue!!)
 
<IfModule alias_module>  
  
#  
# ScriptAlias /cgi-bin/ "C:/xampp/cgi-bin/"  
ScriptAlias /cgi-bin/ "C:/xampp/cgi-bin/ftree/cgi/"  
  
</IfModule>  
  
<Directory "C:/xampp/cgi-bin/ftree/cgi">  
AllowOverride All  
Options None  
Require all granted  
</Directory>  
  
   
3. My shebang in ftree.cgi is #!"c:\Dwimperl\perl\bin\perl.exe" (by Gabor Sabo)  
------------------------
4. I remover included package Params::Validate  
------------------------
because of error  Undefined subroutine Params::Validate::SCALAR perl  
and install new one (1.21)  
 
5. Also I copy
------------------------
c:\xampp\cgi-bin\ftree\graphics\  
  
to  
  
c:\xampp\htdocs\graphics\  
  
to correct show images  
  
6. I catch error couldn't create child process: 720002
------------------------
Because   
If found it !  
It was the first line in the .cgi file that needed to be adapted to Xamp's configuration:  
  
#!"c:\xampp\perl\bin\perl.exe"  
Instead of:  
  
#!"c:\perl\bin\perl.exe"  
  
https://forum.xojo.com/20697-couldn-t-create-child-process-720002-error-when-deploying-on-wi/0  
http://open-server.ru/forum/viewtopic.php?f=6&t=1059  
  
7. Image cancatenate
------------------------
NAME OF THE PICTURE:
  
One picture may belong to each person. The name of the picture file reflects the person it belongs to. The picture file is   obtained from the lowercased full name by substituting spaces with underscores and adding the file extension to it. From   example from "Ferenc Bodon3" we get "ferenc_bodon3.jpg". 

No image put here and name=id.jpg
c:\xampp\cgi-bin\ftree\pictures\  


  
So, It's a good work,  

1. but I prefer some refectoring, move to PSGI  
2. Also, very good if it will be like DWIM  
when you can install it simply click to exe file  
without any others moving.  
 
I'm ready to help with it  
 
Best regards  
Nikolay Mishin  


generate cpanfile  

c:\xampp\cgi-bin\ftree\cgi\lib>perl c:\Users\TOSH\Documents\GitHub\App-scan_prereqs_cpanfile\script\scan-prereqs-cpanfile --ignore=version

