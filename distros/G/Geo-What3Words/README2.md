perl-Geo-What3Words
=======================

Perl CPAN module to turn WGS84 coordinates into three word addresses and vice-versa using what3words.com HTTPS API



DEVELOPMENT

	dzil clean

	# running the test-suite
	TEST_AUTHOR=1 PERLLIB=./lib prove -r t/

	# running the test-suite with calls to w3w
	TEST_AUTHOR=1 PERLLIB=./lib W3W_API_KEY=XXXXX prove -r t/
        
	dzil build

	# git push, upload to CPAN
	dzil release


COPYRIGHT AND LICENCE

Copyright 2019 OpenCage GmbH <cpan@opencagedata.com>


This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10 or,
at your option, any later version of Perl 5 you may have available.
