#!/bin/sh

# need to figure out why this fails
#fatpack trace --use=WWW::Mechanize::Cached --use=CHI --use=LWP::ConsoleLogger::Easy bin/github-mergevelocity

fatpack trace --use=WWW::Mechanize::Cached --use=LWP::ConsoleLogger::Easy bin/github-mergevelocity
fatpack packlists-for `cat fatpacker.trace` >packlists
fatpack tree `cat packlists`
fatpack file bin/github-mergevelocity > bin/ghm-packed.pl
