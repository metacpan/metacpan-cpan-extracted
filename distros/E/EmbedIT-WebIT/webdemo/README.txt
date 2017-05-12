To execute this test simply run the test.pl file. 

You will be able to access the web server via 

http://127.0.0.1:8089/
http://127.0.0.1:8089/pod.html
http://127.0.0.1:8089/test.html
http://127.0.0.1:8089/cgi/broken.pl
http://127.0.0.1:8089/cgi/cgi.sh
http://127.0.0.1:8089/cgi/perl.pl

as well as the error page 

http://127.0.0.1:8089/cgi/error.sh

All the above are just demos of several different ways of using the WebIT server with embeded and external pages written in perl (both embeded and external) and bourne shell scripts.


Enjoy.

PS: If you wish to change the IP and port of the server you need to edit the test.pl file and change the following:

  SERVER_IP   => '127.0.0.1',
  SERVER_PORT => 8089,

  with the IP and port you widh to run the server on.

