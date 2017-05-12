Lithium::WebDriver
==================

The Lithium::Webdriver module is a Selenium / Selenium2 WebDriver compliant interface module,
that makes it easy to connect to a Selenium instance, Phantomjs or Selenium Grid and create,
a WebDriver session. While the Lithium WebDriver is now compatible with the Lithium session
manager it was originally developed to contect with phantomjs, selenium standalone and
selenium.

INSTALLATION
------------

To install this module, run the following commands:

	perl Makefile.PL
	make
	make test
	make install

SUPPORT AND DOCUMENTATION
-------------------------

After installing, you can find documentation for this module with the
perldoc command.

    perldoc Lithium::WebDriver

REFERENCES
----------

  * [JSON Wire Protocol](https://code.google.com/p/selenium/wiki/JsonWireProtocol)
  * [Phantomjs](http://phantomjs.org/)
  * [Ghost Driver](https://github.com/detro/ghostdriver)
  * [Selenium](http://www.seleniumhq.org/)
  * [Selenium Grid](http://www.seleniumhq.org/docs/07_selenium_grid.jsp)

COPYRIGHT AND LICENCE
---------------------

Copyright (C) 2015

Dan Molik, Geoff Franks & James Hunt

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
