#!/usr/bin/perl -w

# Copyright 2010, 2011, 2014, 2019 Kevin Ryde

# This file is part of Filter-gunzip.
#
# Filter-gunzip is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Filter-gunzip is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Filter-gunzip.  If not, see <http://www.gnu.org/licenses/>.



# This was previous code testing PL_rsfp_filters and PL_rsfp layers at the
# perl level.  
#
  # my $filters = _rsfp_filters();
  # ### _rsfp_filters(): $filters
  # 
  # if (
  #     1
  #     # ! defined $filters
  #     # ||
  #     # ($filters && ! @{$filters})
  #    ) {
  #   my $fh;
  #   ### _rsfp(): _rsfp()
  #   if (($fh = _rsfp())
  #       && eval { require PerlIO;
  #                 require PerlIO::gzip;
  #                 1 }) {
  #     ### fh: $fh
  #     ### fileno: fileno($fh)
  #     ### tell: tell($fh)
  # 
  #     my @layers = PerlIO::get_layers($fh);
  #     ### num layers: scalar(@layers)
  #     ### layers: \@layers
  # 
  #     if (@layers && $layers[-1] eq 'crlf') {
  #       ### pop crlf ...
  #       binmode ($fh, ':pop')
  #         or croak "Oops, cannot pop crlf layer: $!";
  #     }
  # 
  #     binmode ($fh, ':gzip')
  #       or croak "Cannot push gzip layer: $!";
  # 
  #     if (@layers && $layers[-1] eq 'crlf') {
  #       ### push crlf again ...
  #       binmode ($fh, ':crlf')
  #         or croak "Oops, cannot re-push crlf layer: $!";
  #     }
  # 
  #     #   @layers = PerlIO::get_layers($fh);
  #     #   ### pushed gzip: \@layers
  #     return;
  #   }
  # }
  # 
  # ### use Filter gunzip Filter ...
  # require Filter::gunzip::Filter;
  # Filter::gunzip::Filter->import;



# Had previously used the accessor functions below and layer checking and
#    install at the perl level.  But in i386 perl 5.30, even just returning
#    PL_rsfp to the perl level does something dubious causing no more source to
#    be read from it.  Dunno why.  Could it be something fishy in the
#    ref-counting causing it to be closed prematurely on the perl level handle
#    going out of scope?  In any case the few lines of XS above work.
# SV *
# _rsfp_filters ()
# CODE:
#     /* printf ("%p\n", PL_parser); */
#     if (PL_parser && PL_rsfp_filters) {
#       /* printf ("%p\n", PL_rsfp_filters); */
#       RETVAL = newRV_inc ((SV *) PL_rsfp_filters);
#     } else {
#       RETVAL = &PL_sv_undef;
#     }
# OUTPUT:
#     RETVAL
# 
# PerlIO *
# _rsfp ()
# CODE:
#     /* This func is only used after _rsfp_filters(), which will notice
#        PL_parser == NULL, so no check for that here. */
#     /* printf ("%p\n", PL_rsfp); */
#     if (! PL_parser) { croak("oops"); }
#     RETVAL = PL_rsfp;
# OUTPUT:
#     RETVAL
