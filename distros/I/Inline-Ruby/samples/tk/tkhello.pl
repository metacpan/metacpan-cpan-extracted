use Inline Ruby => 'require "tk"';

# Create a button widget that prints 'hello', and pack it.
TkButton->new(undef,{text=>'hello',command=>sub{print"hello\n"}})->pack;

# Create a button widget that exits the process, and pack it.
TkButton->new(undef,{text=>'quit',command=>'exit'})->pack;

# Run Tk's mainloop
Tk->mainloop;
