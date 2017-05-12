package Egg::Model::FsaveDate;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: FsaveDate.pm 316 2008-04-17 11:54:05Z lushe $
#
use strict;
use warnings;

our $VERSION= '0.02';

package Egg::Model::FsaveDate::handler;
use strict;
use base qw/ Egg::Model::FsaveDate::Base /;

1;

__END__

=head1 NAME

Egg::Model::FsaveDate - Model to preserve arbitrary text data according to date. 

=head1 SYNOPSIS

  my $fs= $e->model('fsavedate');
  
  my $output_path= $fs->save( <<END_TEXT );
  save data.
  END_TEXT

=head1 DESCRIPTION

The data that wants to be preserved in the file is preserved separately for the 
directory of every the date.

To use it, 'FsaveDate' is added to the MODEL setting of the configuration of the 
project.

  % vi /path/to/MyApp/lib/MyApp/config.pm
   ..........
   MODEL=> [
     [ FsaveDate => {
         base_path => ...........
         ....
         } ],
     ],

Please generate the controller module with L<Egg::Helper::Model::FsaveDate> when
 you want to customize processing.

   % cd /path/to/MyApp/lib/bin
   % ./myapp_helper.pl M::FsaveDate

The antecedent of this module is 'Egg::Plugin::BackUP::Easy'.
This was added, and it operated as a model and some hands were added.

=head1 CONFIGURATION

=head3 base_path

Directory PATH of file output destination.

Default is 'PROJECT_ROOT/etc/FsaveDate'.

=head3 amount_save

When the number of preservation directories under the control of 'base_path' 
exceeds this set value, it deletes it in old the order.

Default is '90'.

=head3 extention

Extension in saved file.

Default is 'txt'.

=head1 CONTROLLER MODULE

It is a method of customizing the controller module generated in the helper script.

First of all, because the name space is a road as shown in model manager's @ISA,
it customizes it in the subordinate's MyApp::Model::FsaveDate::handler though 
controller's package name is MyApp::Model::FsaveDate.

The configuration is set in this handler, and an existing if necessary method is
 Obarraided.

  package MyApp::Model::FsaveDate::handler;
  
  __PACKAGE__->config( .......... );

For instance, to convert the character-code of the preserved text into the 
arbitrary one, 'create_body' method is Orbaraided.

  sub create_body {
     my($self, $text)= @_;
     $$text=~tr/\n/\r\n/;
     return Jcode->new($text)->sjis;
  }

Passed $text is passed by the SCALAR reference. After this is processed, it 
returns it with usual SCALAR.

Additionally, there are 'create_dir_name' and 'create_file_name' in the method
 of possible override. Please refer to the source code for details for the 
processing method etc.

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Model::FsaveDate::Base>,
L<Egg::Helper::Model::FsaveDate>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Bee Flag, Corp. E<lt>http://egg.bomcity.com/E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

