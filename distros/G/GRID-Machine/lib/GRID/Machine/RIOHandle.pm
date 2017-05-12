############# Remote IO ###############
use strict;

# Class methods

LOCAL {
  for (qw(format_line_break_characters 
          format_formfeed 
          output_field_separator 
          input_record_separator
          output_record_separator
         )
      ) {
    SERVER()->sub(
         "$_",                     #  sub input_record_separator
        'IO::Handle->'.$_.'(@_);', #    IO::Handle->input_record_separator(@_);
      filter => 'result');
  }

  for (qw(
          print
          printf
          flush
          autoflush
          blocking
          getline
          getlines
          stat
         )
      ) {
    SERVER()->sub("$_", q{  # sub print
          my $index = shift();
          $index = $index->{index} if blessed($index);
          my $f = SERVER()->{FILES}[$index];
        }
        .'$f->'.$_.'(@_);', # $f->print(@_);
   );
  }
};

############ object methods

sub getc {
   my $index = shift();
   $index = $index->{index} if blessed($index);
   my $f = SERVER()->{FILES}[$index];
   $f->getc();
}

sub close {
   my $index = shift();
   $index = $index->{index} if blessed($index);
   my $f = SERVER()->{FILES}[$index];
   $f->close();
   delete SERVER()->{FILES}[$index];
}

sub read {
   my $index = shift();
   $index = $index->{index} if blessed($index);
   my $f = SERVER()->{FILES}[$index];

   my $buffer;
   $f->read($buffer, @_);
   return $buffer;
}

sub sysread {
   my $index = shift();
   $index = $index->{index} if blessed($index);
   my $f = SERVER()->{FILES}[$index];

   my $buffer;
   $f->sysread($buffer, @_);
   return $buffer;
}

sub diamond {
   my $index = shift();
   $index = $index->{index} if blessed($index);
   my $context = shift();

   my $f = SERVER()->{FILES}[$index];

   return scalar(<$f>);
}

__END__

=head1 NAME

GRID::Machine::RIOHandle - Remote side of the Remote Input-Output

=head1 DESCRIPTION

This file is a I<Remote Module>.
Contains the remote side of the Remote Input-Output
operations. Is loaded via C<GRID::Machine::include>
when the C<GRID::Machine> object is created. The local partner of this
remote module is GRID::Machine::IOHandle


