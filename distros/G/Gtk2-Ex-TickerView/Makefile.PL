#!/usr/bin/perl

# Copyright 2007, 2008, 2009, 2010 Kevin Ryde

# This file is part of Gtk2-Ex-TickerView.
#
# Gtk2-Ex-TickerView is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-TickerView is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-TickerView.  If not, see <http://www.gnu.org/licenses/>.

use 5.008;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use lib 'inc';
use MyMakeMakerExtras;

MyMakeMakerExtras::WriteMakefile
  (NAME         => 'Gtk2-Ex-TickerView',
   ABSTRACT     => 'Scrolling ticker or newsbar view widget.',
   VERSION_FROM => 'lib/Gtk2/Ex/TickerView.pm',
   AUTHOR       => 'Kevin Ryde <user42@zip.com.au>',
   LICENSE      => 'gpl',
   SIGN         => 1,

   MIN_PERL_VERSION => '5.008',
   PREREQ_PM    => {
                    'Glib' => 0,
                    'Glib::Object::Subclass' => 0,

                    # need 1.180 or higher to be able to implement
                    # Gtk2::CellLayout as a GInterface
                    'Gtk2' => '1.180',

                    # version 4 for _cellinfo_starts
                    'Gtk2::Ex::CellLayout::Base' => 4,

                    # my Gtk2-Ex-WidgetBits
                    'Gtk2::Ex::SyncCall' => 12,

                    # my Glib-Ex-ObjectBits
                    'Glib::Ex::SignalIds' => 1,
                    'Glib::Ex::SourceIds' => 2,  # new in version 2
                   },


   META_MERGE
   => { resources
        => { homepage
             => 'http://user42.tuxfamily.org/gtk2-ex-tickerview/index.html',
           },
        optional_features
        => { maximum_tests
             => { description => 'Have "make test" do as much as possible.',
                  requires => { 'Test::Weaken' => '2.000',
                                'Test::Weaken::Gtk2' => 24,
                                'Devel::FindRef' => 0,
                              },
                },
             maximum_examples
             => { description => 'Be able to run all the example programs.',
                  requires => { 'Finance::Quote'  => 0,
                                'Gtk2'            => 0,
                                'HTTP::Request'   => 0,
                                'URI::Escape'     => 0,
                                'POE'             => 0,
                                'POE::Loop::Glib' => 0,
                                'POE::Component::Client::HTTP' => 0,
                              },
                },
             maximum_devel
             => { description => 'Stuff used variously for development.',
                  requires => { 'Glib::Ex::ConnectProperties' => 0,
                                'Devel::StackTrace'           => 0,
                                'Devel::FindRef'              => 0,
                                'Devel::Peek'                 => 0,
                              },
                },
           },
      },

   MyMakeMakerExtras_Pod_Coverage
   => [ 'Gtk2::Ex::TickerView,also_private=>[qr/^[A-Z_]+$$/]' ],
  );
