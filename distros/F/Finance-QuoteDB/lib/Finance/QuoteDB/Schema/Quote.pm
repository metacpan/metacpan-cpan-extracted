package Finance::QuoteDB::Schema::Quote;
use base qw/DBIx::Class/;

our $VERSION = '0.18'; # VERSION

use strict;
use warnings;

__PACKAGE__->load_components(qw/ PK::Auto Core /);
__PACKAGE__->table('quote');
__PACKAGE__->add_columns ( symbolID=> { data_type=>'varchar',
                                        size=>20,
                                        is_nullable=>0,
                                        is_auto_increment=>0,
                                        default_value=>''
                                      },
                           date=> { data_type=>'date',
                                    is_nullable=>0,
                                    is_auto_increment=>0,
                                    default_value=>''
                                  },
                           previous_close=> { data_type=>'float',
                                              is_nullable=>1,
                                              is_auto_increment=>0,
                                              default_value=>0
                                            },
                           day_open=> { data_type=>'float',
                                        is_nullable=>1,
                                        is_auto_increment=>0,
                                        default_value=>0
                                      },
                           day_high=> { data_type=>'float',
                                        is_nullable=>1,
                                        is_auto_increment=>0,
                                        default_value=>0
                                      },
                           day_low=> { data_type=>'float',
                                       is_nullable=>1,
                                       is_auto_increment=>0,
                                       default_value=>0
                                     },
                           day_close=> { data_type=>'float',
                                         is_nullable=>1,
                                         is_auto_increment=>0,
                                         default_value=>0
                                       },
                           bid=> { data_type=>'integer',
                                   is_nullable=>1,
                                   is_auto_increment=>0,
                                   default_value=>0
                                 },
                           ask=> { data_type=>'integer',
                                   is_nullable=>1,
                                   is_auto_increment=>0,
                                   default_value=>0
                                 },
                           volume=> { data_type=>'integer',
                                      is_nullable=>1,
                                      is_auto_increment=>0,
                                      default_value=>0
                                    }
                         );

__PACKAGE__->set_primary_key(qw / symbolID date /);
__PACKAGE__->belongs_to('symbolID'=>'Finance::QuoteDB::Schema::Symbol');

=head1 COPYRIGHT & LICENSE

Copyright 2008-2011 Erik Colson, all rights reserved.

This file is part of Finance::QuoteDB.

Finance::QuoteDB is free software: you can redistribute it and/or
modify it under the terms of the GNU General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

Finance::QuoteDB is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with Finance::QuoteDB.  If not, see
<http://www.gnu.org/licenses/>.

=cut

1;
