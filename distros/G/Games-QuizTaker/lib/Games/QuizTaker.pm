package Games::QuizTaker;
{
  use strict;
  use Text::Wrap;
  use Fcntl qw/:flock/;
  use Carp;
  use Data::Dumper;
  use Object::InsideOut;
  use vars qw($TESTONLY $VERSION);
  use Games::QuizTaker::IO;

  $VERSION='2.1';
  my $questions={};
  my %Randoms=();
  my @Randoms=();
  my %Test_Questions=();
  my %Test_Answers=();
  my $t;

  my @FileName :Field('Standard'=>'FileName','Type'=>'LIST');
  my @AnswerDelimiter :Field('Standard'=>'AnswerDelimiter','Type'=>'LIST');
  my @FileLength :Field('Standard'=>'FileLength','Type'=>'NUMERIC');
  my @Delimiter :Field('Standard'=>'Delimiter','Type'=>'LIST');
  my @MaxQuestions :Field('Standard'=>'MaxQuestions','Type'=>'NUMERIC');
  my @Score :Field('Standard'=>'Score','Type'=>'NUMERIC');
  
  my %init_args :InitArgs=(
      'FileName'=>{                     # Name of file with questions
        'Regex' => qr/^FileName$/i,
        'Mandatory' => 1,
      },
      'AnswerDelimiter'=>{              # This is the delimiter that separates multiple answers
        'Regex'=>qr/AnswerDelimiter/i,  # It is a space by default
        'Default'=>" ",
      },
      'FileLength'=>{                   # This is the number of questions in the file
        'Regex'=>qr/FileLength/,        # It is set when the question file is loaded
        'Default'=>0
      },
      'Delimiter'=>{                    # This is the delimiter that separates the questions and choices.
        'Regex'=>qr/Delimiter/i,        # It is the pipe | character by default
        'Default'=>"|"
      },
      'MaxQuestions'=>{                 # This is the maximum number of questions that can be asked for the test
        'Regex'=>qr/MaxQuestions/,      
        'Default'=>undef
      },
      'Score'=>{                        # This controls whether or not you want an overall score printed out
        'Regex'=>qr/Score/i,
        'Default'=>undef
      },
  );
  
  sub _init :Init{
    my ($self,$args)=@_;
    if(exists($args->{'FileName'})){
      $self->set(\@FileName,$args->{'FileName'});
    }
    if(exists($args->{'AnswerDelimiter'})){
      $self->set(\@AnswerDelimiter,$args->{'AnswerDelimiter'});
    }
    if(exists($args->{'Delimiter'})){
      $self->set(\@Delimiter,$args->{'Delimiter'});
    }
    if(exists($args->{'Score'})){
      $self->set(\@Score,$args->{'Score'});
    }
    if(exists($args->{'MaxQuestions'})){
      $self->set(\@MaxQuestions,$args->{'MaxQuestions'});
    }
    if(exists($args->{'FileLength'})){
      $self->set(\@FileLength,$args->{'FileLength'});
    }
    my $ad=$self->get_AnswerDelimiter;
    my $dl=$self->get_Delimiter;
    if($ad eq $dl){ croak"The Delimiter and Answer Delimiter are the same!"; }
  }
  
  sub load{
    my $self=shift;
    my $delimiter=$self->get_Delimiter;
    my $file=$self->get_FileName;
    my ($question_number,$count);
    
    open(FH,"$file")||croak"Can't open $file: $!";
    flock(FH,LOCK_SH);
    while(<FH>){
      my @sorter;
      if(/^$/ or /^#/){}else{
        $count++;
        my $sep=qq"\\$delimiter"; 
        @sorter=split /$sep/;
        $question_number=shift @sorter;
        my $ref=\@sorter;
        $$questions{$question_number}=$ref;    
      }
    }
    flock(FH,LOCK_UN);
    close FH;
    $self->set_FileLength($count);
  }
  
  sub generate{
    my $self=shift;
    my $Total_Questions=$self->get_FileLength;
    
    if(!defined $self->get_MaxQuestions){
      $self->set_MaxQuestions($Total_Questions);
    }
    
    my $Max_Questions=$self->get_MaxQuestions;
    
    for(1..$Max_Questions){
      my $question_number=int(rand($Total_Questions)+1);
      redo if exists $Randoms{$question_number};
      $Randoms{$question_number}=1;
    }

    @Randoms=keys %Randoms;
    $self->shuffle(\@Randoms);
    
    for(my $D=0;$D<$Max_Questions;$D++){
      $Test_Answers{$Randoms[$D]}=pop @{$$questions{$Randoms[$D]}};
      $Test_Questions{$Randoms[$D]} = $$questions{$Randoms[$D]};
    }
    $TESTONLY=$$questions{'1'}[0];
}
  
  sub test{
    my $self=shift;
    my $Answer_Sep=$self->get_AnswerDelimiter;
    my $Max=$self->get_MaxQuestions;
    my ($answer,$key,$line,$question_answer);
    my $question_number=1;
    my $number_correct=0;
    my $asep=qq"\\$Answer_Sep";
    system(($^O eq "MSWin32"?'cls':'clear'));
    print"\n";

    while($question_number<=$Max){
      $key=shift @Randoms;
  
      print"Question Number $question_number\n";
      $t=$$questions{$key}[0];      #Used for module testing
      foreach $line(@{$$questions{$key}}){
       Games::QuizTaker::IO::out(wrap("","","$line\n"));
      }

      print"Your Answer: ";
      $answer=Games::QuizTaker::IO::in; 
      chomp($answer);
      $answer=uc($answer);
      $question_answer=$Test_Answers{$key};
      chomp($question_answer);
      $question_answer=uc $question_answer;
      my $ln=length($question_answer);

      if($ln>1){
        if($question_answer!~/$Answer_Sep/){
          warn"Answer_Delimiter doesn't match internally";
        }
        if($Answer_Sep eq " "){ }else{
          $question_answer=~s/$asep/ /;
        }
        $question_answer=$self->answer_sort($question_answer);
        $answer=$self->answer_sort($answer); 
      }

       if("$answer" eq "$question_answer"){
        print"That is correct!!\n\n";
        $question_number++;
        $number_correct++;
      }else{
        print"That is incorrect!!\n";
        print"The correct answer is $question_answer.\n\n";
        $question_number++;
      }
    }
    my $Final=$self->get_Score;
    if(defined $Final){
      $self->Final($number_correct,$Max);
      return;
    }else{
      return;
    }
  }

  sub answer_sort{
    my ($self,$answer)=@_;
    my @array=split //,$answer;
    my @sorted=sort @array;
    $answer=join ' ',@sorted;
    return $answer;
  }

  sub Final{
    my ($self,$Correct,$Max)=@_;
  
    if($Correct >= 1){
      my $Percentage=($Correct/$Max)*100;
      print"You answered $Correct out of $Max correctly.\n";
      printf"For a final score of %02d%%\n",$Percentage;
      return;
    }else{
      print"You answered 0 out of $Max correctly.\n";
      print"For a final score of 0%\n";
      return;
    }
  } 
  sub shuffle{
  ## Fisher-Yates shuffle ##
    my ($self,$array)=@_;
    my $x;
    for($x=@$array;--$x;){
      my $y=int rand ($x+1);
      next if $x == $y;
      @$array[$x,$y]=@$array[$y,$x];
    }
  }
  sub DESTROY{
    my $self=shift;
    unlink $self;
  }
}
1;
__END__

=pod

=head1 NAME

Games::QuizTaker - Take your own quizzes and tests

=head1 SYNAPSIS

  use Games::QuizTaker;
  my $GQ=Games::QuizTaker->new(FileName=>'test.psv');
  $GQ->load;
  $GQ->set_MaxQuestions(2) # Set the number of questions you wish to answer on the test. This is optional.
  $GQ->generate;
  $GQ->test;

=head1 DESCRIPTION

=over 5

=item new

 C<< my $GQT=Games::QuizTaker->new(FileName=>"File",Delimiter=>",",AnswerDelimiter=>"|",Score=>1); >>

 This method creates the Games::QuizTaker object as an inside out object. The method can take up to four arguments, and one of them
 (FileName) is mandatory. If the FileName argument is not passed, the method will croak. The Delimiter argument is the separator within the
 file that separates the question number, the question, its answers, and the correct answer. The AnswerDelimiter is used to separate the answers
 of questions that have multiple answers. The Score method takes a numeric argument. If set to 1, it will print out an overall score at the end
 of the test. If left undefined(the default), it will not print the results. This is useful if setup in a login script to do a single question at
 login.

 The default for the Delimiter parameter is the pipe "|" chararcter, and the default for the AnswerDelimiter is a space. Also note that while the method names
 are case-sensitive, the parameter names are not, so the parameters can be spelled in all lower case and the object will still put the parameters and 
 their arguments exactly where they belong.

=item load

 C<< $GQT->load; >>

 This method loads the question file into the object, and sets the internal FileLength parameter.

=item generate

 C<< $GQT->generate; >>

 This method will load all of the questions and answers into the test hashes by default, unless the MaxQuestions internal parameter
 has been set. This is checked for at the beginning of the method
 
=item test

C<< $GQT->test; >>

 This method actually prints the questions out and waits for the answer input. It will check the user's input against the correct answer
 and report back if they match or not.
 
=item get/set methods

 The purpose of these methods should be self-explanatory, so I won't go into them other than to provide a list of them:

 get_FileName,set_FileName
 get_AnswerDelimeter,set_AnswerDelimeter
 get_Delimeter,set_Delimeter
 get_Score,set_Score
 get_FileLength,set_FileLength
 get_MaxQuestions,set_MaxQuestions

=back

=head1 EXPORT

 None by default

=head1 DEBUGGING

 None by default

=head1 TODO LIST

 None by default

=head1 ACKNOWLEDGEMENTS

Thanks to Jerry D. Heden for creating the Object::InsideOut module which I used to create this version of Games::QuizTaker.
Thanks to Damian Conway for his book "Perl Best Practices" which gave me the initial idea to use an insideout object to implement the module

=head1 AUTHOR

Thomas Stanley

Thomas_J_Stanley@msn.com

I can also be found at http://www.perlmonks.org as TStanley. You can also direct
any questions relating to this module there.

=head1 COPYRIGHT

=begin text

Copyright (C)2001-2006 Thomas Stanley. All rights reserved. This program is free
software; you can redistribute it and/or modify it under the same terms as
Perl itself.

=end text

=begin html

Copyright E<copy>2001-2006 Thomas Stanley. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same terms
as Perl itself.

=end html

=head1 SEE ALSO

I<perl(1)>
I<Object::InsideOut>

=cut

