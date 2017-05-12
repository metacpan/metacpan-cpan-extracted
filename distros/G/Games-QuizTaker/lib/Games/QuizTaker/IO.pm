package Games::QuizTaker::IO;
{
  sub in{
    return scalar <STDIN>;
  }

  sub out{
    print @_;
  }

1;
}

