#!/usr/bin/perl -w

# Copyright 2011 Kevin Ryde

# This file is part of Glib-Ex-ObjectBits.
#
# Glib-Ex-ObjectBits is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Glib-Ex-ObjectBits is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Glib-Ex-ObjectBits.  If not, see <http://www.gnu.org/licenses/>.

use 5.010;
use strict;
use warnings;
use Glib;

# uncomment this to run the ### lines
use Smart::Comments;

my $context = Glib::MainContext->new;
### $context;
### is_owner: $context->is_owner
### iteration: $context->iteration(0)

my $default_context = Glib::MainContext->default;
### $default_context
### is_owner: $default_context->is_owner
### iteration: $default_context->iteration(0)
