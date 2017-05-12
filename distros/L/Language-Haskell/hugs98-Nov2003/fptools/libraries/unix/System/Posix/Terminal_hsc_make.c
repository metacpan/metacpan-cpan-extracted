#include "template-hsc.h"
#line 67 "Terminal.hsc"
#include "HsUnix.h"

int main (int argc, char *argv [])
{
#if __GLASGOW_HASKELL__ && __GLASGOW_HASKELL__ < 409
    printf ("{-# OPTIONS -optc-D__GLASGOW_HASKELL__=%d #-}\n", 603);
#endif
    printf ("{-# OPTIONS %s #-}\n", "-#include \"HsUnix.h\"");
    hsc_line (1, "Terminal.hsc");
    fputs ("{-# OPTIONS -fffi #-}\n"
           "", stdout);
    hsc_line (2, "Terminal.hsc");
    fputs ("-----------------------------------------------------------------------------\n"
           "-- |\n"
           "-- Module      :  System.Posix.Terminal\n"
           "-- Copyright   :  (c) The University of Glasgow 2002\n"
           "-- License     :  BSD-style (see the file libraries/base/LICENSE)\n"
           "-- \n"
           "-- Maintainer  :  libraries@haskell.org\n"
           "-- Stability   :  provisional\n"
           "-- Portability :  non-portable (requires POSIX)\n"
           "--\n"
           "-- POSIX Terminal support\n"
           "--\n"
           "-----------------------------------------------------------------------------\n"
           "\n"
           "module System.Posix.Terminal (\n"
           "  -- * Terminal support\n"
           "\n"
           "  -- ** Terminal attributes\n"
           "  TerminalAttributes,\n"
           "  getTerminalAttributes,\n"
           "  TerminalState(..),\n"
           "  setTerminalAttributes,\n"
           "\n"
           "  TerminalMode(..),\n"
           "  withoutMode,\n"
           "  withMode,\n"
           "  terminalMode,\n"
           "  bitsPerByte,\n"
           "  withBits,\n"
           "\n"
           "  ControlCharacter(..),\n"
           "  controlChar,\n"
           "  withCC,\n"
           "  withoutCC,\n"
           "\n"
           "  inputTime,\n"
           "  withTime,\n"
           "  minInput,\n"
           "  withMinInput,\n"
           "\n"
           "  BaudRate(..),\n"
           "  inputSpeed,\n"
           "  withInputSpeed,\n"
           "  outputSpeed,\n"
           "  withOutputSpeed,\n"
           "\n"
           "  -- ** Terminal operations\n"
           "  sendBreak,\n"
           "  drainOutput,\n"
           "  QueueSelector(..),\n"
           "  discardData,\n"
           "  FlowAction(..),\n"
           "  controlFlow,\n"
           "\n"
           "  -- ** Process groups\n"
           "  getTerminalProcessGroupID,\n"
           "  setTerminalProcessGroupID,\n"
           "\n"
           "  -- ** Testing a file descriptor\n"
           "  queryTerminal,\n"
           "  getTerminalName,\n"
           "  getControllingTerminalName\n"
           "\n"
           "  ) where\n"
           "\n"
           "", stdout);
    fputs ("\n"
           "", stdout);
    hsc_line (68, "Terminal.hsc");
    fputs ("\n"
           "import Data.Bits\n"
           "import Data.Char\n"
           "import Foreign.C.Error ( throwErrnoIfMinus1, throwErrnoIfMinus1_, throwErrnoIfNull )\n"
           "import Foreign.C.String ( CString, peekCString )\n"
           "import Foreign.C.Types ( CInt )\n"
           "import Foreign.ForeignPtr ( ForeignPtr, withForeignPtr, mallocForeignPtrBytes )\n"
           "import Foreign.Marshal.Utils ( copyBytes )\n"
           "import Foreign.Ptr ( Ptr, nullPtr, plusPtr )\n"
           "import Foreign.Storable ( Storable(..) )\n"
           "import System.IO.Unsafe ( unsafePerformIO )\n"
           "import System.Posix.Types\n"
           "\n"
           "-- -----------------------------------------------------------------------------\n"
           "-- Terminal attributes\n"
           "\n"
           "type CTermios = ()\n"
           "newtype TerminalAttributes = TerminalAttributes (ForeignPtr CTermios)\n"
           "\n"
           "makeTerminalAttributes :: ForeignPtr CTermios -> TerminalAttributes\n"
           "makeTerminalAttributes = TerminalAttributes\n"
           "\n"
           "withTerminalAttributes :: TerminalAttributes -> (Ptr CTermios -> IO a) -> IO a\n"
           "withTerminalAttributes (TerminalAttributes termios) = withForeignPtr termios\n"
           "\n"
           "\n"
           "data TerminalMode\n"
           "\t-- input flags\n"
           "   = InterruptOnBreak\t\t-- BRKINT\n"
           "   | MapCRtoLF\t\t\t-- ICRNL\n"
           "   | IgnoreBreak\t\t-- IGNBRK\n"
           "   | IgnoreCR\t\t\t-- IGNCR\n"
           "   | IgnoreParityErrors\t\t-- IGNPAR\n"
           "   | MapLFtoCR\t\t\t-- INLCR\n"
           "   | CheckParity\t\t-- INPCK\n"
           "   | StripHighBit\t\t-- ISTRIP\n"
           "   | StartStopInput\t\t-- IXOFF\n"
           "   | StartStopOutput\t\t-- IXON\n"
           "   | MarkParityErrors\t\t-- PARMRK\n"
           "\n"
           "\t-- output flags\n"
           "   | ProcessOutput\t\t-- OPOST\n"
           "\t-- ToDo: ONLCR, OCRNL, ONOCR, ONLRET, OFILL,\n"
           "\t--       NLDLY(NL0,NL1), CRDLY(CR0,CR1,CR2,CR2)\n"
           "\t--\t TABDLY(TAB0,TAB1,TAB2,TAB3)\n"
           "\t--\t BSDLY(BS0,BS1), VTDLY(VT0,VT1), FFDLY(FF0,FF1)\n"
           "\n"
           "\t-- control flags\n"
           "   | LocalMode\t\t\t-- CLOCAL\n"
           "   | ReadEnable\t\t\t-- CREAD\n"
           "   | TwoStopBits\t\t-- CSTOPB\n"
           "   | HangupOnClose\t\t-- HUPCL\n"
           "   | EnableParity\t\t-- PARENB\n"
           "   | OddParity\t\t\t-- PARODD\n"
           "\n"
           "\t-- local modes\n"
           "   | EnableEcho\t\t\t-- ECHO\n"
           "   | EchoErase\t\t\t-- ECHOE\n"
           "   | EchoKill\t\t\t-- ECHOK\n"
           "   | EchoLF\t\t\t-- ECHONL\n"
           "   | ProcessInput\t\t-- ICANON\n"
           "   | ExtendedFunctions\t\t-- IEXTEN\n"
           "   | KeyboardInterrupts\t\t-- ISIG\n"
           "   | NoFlushOnInterrupt\t\t-- NOFLSH\n"
           "   | BackgroundWriteInterrupt\t-- TOSTOP\n"
           "\n"
           "withoutMode :: TerminalAttributes -> TerminalMode -> TerminalAttributes\n"
           "withoutMode termios InterruptOnBreak = clearInputFlag (", stdout);
#line 135 "Terminal.hsc"
    hsc_const (BRKINT);
    fputs (") termios\n"
           "", stdout);
    hsc_line (136, "Terminal.hsc");
    fputs ("withoutMode termios MapCRtoLF = clearInputFlag (", stdout);
#line 136 "Terminal.hsc"
    hsc_const (ICRNL);
    fputs (") termios\n"
           "", stdout);
    hsc_line (137, "Terminal.hsc");
    fputs ("withoutMode termios IgnoreBreak = clearInputFlag (", stdout);
#line 137 "Terminal.hsc"
    hsc_const (IGNBRK);
    fputs (") termios\n"
           "", stdout);
    hsc_line (138, "Terminal.hsc");
    fputs ("withoutMode termios IgnoreCR = clearInputFlag (", stdout);
#line 138 "Terminal.hsc"
    hsc_const (IGNCR);
    fputs (") termios\n"
           "", stdout);
    hsc_line (139, "Terminal.hsc");
    fputs ("withoutMode termios IgnoreParityErrors = clearInputFlag (", stdout);
#line 139 "Terminal.hsc"
    hsc_const (IGNPAR);
    fputs (") termios\n"
           "", stdout);
    hsc_line (140, "Terminal.hsc");
    fputs ("withoutMode termios MapLFtoCR = clearInputFlag (", stdout);
#line 140 "Terminal.hsc"
    hsc_const (INLCR);
    fputs (") termios\n"
           "", stdout);
    hsc_line (141, "Terminal.hsc");
    fputs ("withoutMode termios CheckParity = clearInputFlag (", stdout);
#line 141 "Terminal.hsc"
    hsc_const (INPCK);
    fputs (") termios\n"
           "", stdout);
    hsc_line (142, "Terminal.hsc");
    fputs ("withoutMode termios StripHighBit = clearInputFlag (", stdout);
#line 142 "Terminal.hsc"
    hsc_const (ISTRIP);
    fputs (") termios\n"
           "", stdout);
    hsc_line (143, "Terminal.hsc");
    fputs ("withoutMode termios StartStopInput = clearInputFlag (", stdout);
#line 143 "Terminal.hsc"
    hsc_const (IXOFF);
    fputs (") termios\n"
           "", stdout);
    hsc_line (144, "Terminal.hsc");
    fputs ("withoutMode termios StartStopOutput = clearInputFlag (", stdout);
#line 144 "Terminal.hsc"
    hsc_const (IXON);
    fputs (") termios\n"
           "", stdout);
    hsc_line (145, "Terminal.hsc");
    fputs ("withoutMode termios MarkParityErrors = clearInputFlag (", stdout);
#line 145 "Terminal.hsc"
    hsc_const (PARMRK);
    fputs (") termios\n"
           "", stdout);
    hsc_line (146, "Terminal.hsc");
    fputs ("withoutMode termios ProcessOutput = clearOutputFlag (", stdout);
#line 146 "Terminal.hsc"
    hsc_const (OPOST);
    fputs (") termios\n"
           "", stdout);
    hsc_line (147, "Terminal.hsc");
    fputs ("withoutMode termios LocalMode = clearControlFlag (", stdout);
#line 147 "Terminal.hsc"
    hsc_const (CLOCAL);
    fputs (") termios\n"
           "", stdout);
    hsc_line (148, "Terminal.hsc");
    fputs ("withoutMode termios ReadEnable = clearControlFlag (", stdout);
#line 148 "Terminal.hsc"
    hsc_const (CREAD);
    fputs (") termios\n"
           "", stdout);
    hsc_line (149, "Terminal.hsc");
    fputs ("withoutMode termios TwoStopBits = clearControlFlag (", stdout);
#line 149 "Terminal.hsc"
    hsc_const (CSTOPB);
    fputs (") termios\n"
           "", stdout);
    hsc_line (150, "Terminal.hsc");
    fputs ("withoutMode termios HangupOnClose = clearControlFlag (", stdout);
#line 150 "Terminal.hsc"
    hsc_const (HUPCL);
    fputs (") termios\n"
           "", stdout);
    hsc_line (151, "Terminal.hsc");
    fputs ("withoutMode termios EnableParity = clearControlFlag (", stdout);
#line 151 "Terminal.hsc"
    hsc_const (PARENB);
    fputs (") termios\n"
           "", stdout);
    hsc_line (152, "Terminal.hsc");
    fputs ("withoutMode termios OddParity = clearControlFlag (", stdout);
#line 152 "Terminal.hsc"
    hsc_const (PARODD);
    fputs (") termios\n"
           "", stdout);
    hsc_line (153, "Terminal.hsc");
    fputs ("withoutMode termios EnableEcho = clearLocalFlag (", stdout);
#line 153 "Terminal.hsc"
    hsc_const (ECHO);
    fputs (") termios\n"
           "", stdout);
    hsc_line (154, "Terminal.hsc");
    fputs ("withoutMode termios EchoErase = clearLocalFlag (", stdout);
#line 154 "Terminal.hsc"
    hsc_const (ECHOE);
    fputs (") termios\n"
           "", stdout);
    hsc_line (155, "Terminal.hsc");
    fputs ("withoutMode termios EchoKill = clearLocalFlag (", stdout);
#line 155 "Terminal.hsc"
    hsc_const (ECHOK);
    fputs (") termios\n"
           "", stdout);
    hsc_line (156, "Terminal.hsc");
    fputs ("withoutMode termios EchoLF = clearLocalFlag (", stdout);
#line 156 "Terminal.hsc"
    hsc_const (ECHONL);
    fputs (") termios\n"
           "", stdout);
    hsc_line (157, "Terminal.hsc");
    fputs ("withoutMode termios ProcessInput = clearLocalFlag (", stdout);
#line 157 "Terminal.hsc"
    hsc_const (ICANON);
    fputs (") termios\n"
           "", stdout);
    hsc_line (158, "Terminal.hsc");
    fputs ("withoutMode termios ExtendedFunctions = clearLocalFlag (", stdout);
#line 158 "Terminal.hsc"
    hsc_const (IEXTEN);
    fputs (") termios\n"
           "", stdout);
    hsc_line (159, "Terminal.hsc");
    fputs ("withoutMode termios KeyboardInterrupts = clearLocalFlag (", stdout);
#line 159 "Terminal.hsc"
    hsc_const (ISIG);
    fputs (") termios\n"
           "", stdout);
    hsc_line (160, "Terminal.hsc");
    fputs ("withoutMode termios NoFlushOnInterrupt = setLocalFlag (", stdout);
#line 160 "Terminal.hsc"
    hsc_const (NOFLSH);
    fputs (") termios\n"
           "", stdout);
    hsc_line (161, "Terminal.hsc");
    fputs ("withoutMode termios BackgroundWriteInterrupt = clearLocalFlag (", stdout);
#line 161 "Terminal.hsc"
    hsc_const (TOSTOP);
    fputs (") termios\n"
           "", stdout);
    hsc_line (162, "Terminal.hsc");
    fputs ("\n"
           "withMode :: TerminalAttributes -> TerminalMode -> TerminalAttributes\n"
           "withMode termios InterruptOnBreak = setInputFlag (", stdout);
#line 164 "Terminal.hsc"
    hsc_const (BRKINT);
    fputs (") termios\n"
           "", stdout);
    hsc_line (165, "Terminal.hsc");
    fputs ("withMode termios MapCRtoLF = setInputFlag (", stdout);
#line 165 "Terminal.hsc"
    hsc_const (ICRNL);
    fputs (") termios\n"
           "", stdout);
    hsc_line (166, "Terminal.hsc");
    fputs ("withMode termios IgnoreBreak = setInputFlag (", stdout);
#line 166 "Terminal.hsc"
    hsc_const (IGNBRK);
    fputs (") termios\n"
           "", stdout);
    hsc_line (167, "Terminal.hsc");
    fputs ("withMode termios IgnoreCR = setInputFlag (", stdout);
#line 167 "Terminal.hsc"
    hsc_const (IGNCR);
    fputs (") termios\n"
           "", stdout);
    hsc_line (168, "Terminal.hsc");
    fputs ("withMode termios IgnoreParityErrors = setInputFlag (", stdout);
#line 168 "Terminal.hsc"
    hsc_const (IGNPAR);
    fputs (") termios\n"
           "", stdout);
    hsc_line (169, "Terminal.hsc");
    fputs ("withMode termios MapLFtoCR = setInputFlag (", stdout);
#line 169 "Terminal.hsc"
    hsc_const (INLCR);
    fputs (") termios\n"
           "", stdout);
    hsc_line (170, "Terminal.hsc");
    fputs ("withMode termios CheckParity = setInputFlag (", stdout);
#line 170 "Terminal.hsc"
    hsc_const (INPCK);
    fputs (") termios\n"
           "", stdout);
    hsc_line (171, "Terminal.hsc");
    fputs ("withMode termios StripHighBit = setInputFlag (", stdout);
#line 171 "Terminal.hsc"
    hsc_const (ISTRIP);
    fputs (") termios\n"
           "", stdout);
    hsc_line (172, "Terminal.hsc");
    fputs ("withMode termios StartStopInput = setInputFlag (", stdout);
#line 172 "Terminal.hsc"
    hsc_const (IXOFF);
    fputs (") termios\n"
           "", stdout);
    hsc_line (173, "Terminal.hsc");
    fputs ("withMode termios StartStopOutput = setInputFlag (", stdout);
#line 173 "Terminal.hsc"
    hsc_const (IXON);
    fputs (") termios\n"
           "", stdout);
    hsc_line (174, "Terminal.hsc");
    fputs ("withMode termios MarkParityErrors = setInputFlag (", stdout);
#line 174 "Terminal.hsc"
    hsc_const (PARMRK);
    fputs (") termios\n"
           "", stdout);
    hsc_line (175, "Terminal.hsc");
    fputs ("withMode termios ProcessOutput = setOutputFlag (", stdout);
#line 175 "Terminal.hsc"
    hsc_const (OPOST);
    fputs (") termios\n"
           "", stdout);
    hsc_line (176, "Terminal.hsc");
    fputs ("withMode termios LocalMode = setControlFlag (", stdout);
#line 176 "Terminal.hsc"
    hsc_const (CLOCAL);
    fputs (") termios\n"
           "", stdout);
    hsc_line (177, "Terminal.hsc");
    fputs ("withMode termios ReadEnable = setControlFlag (", stdout);
#line 177 "Terminal.hsc"
    hsc_const (CREAD);
    fputs (") termios\n"
           "", stdout);
    hsc_line (178, "Terminal.hsc");
    fputs ("withMode termios TwoStopBits = setControlFlag (", stdout);
#line 178 "Terminal.hsc"
    hsc_const (CSTOPB);
    fputs (") termios\n"
           "", stdout);
    hsc_line (179, "Terminal.hsc");
    fputs ("withMode termios HangupOnClose = setControlFlag (", stdout);
#line 179 "Terminal.hsc"
    hsc_const (HUPCL);
    fputs (") termios\n"
           "", stdout);
    hsc_line (180, "Terminal.hsc");
    fputs ("withMode termios EnableParity = setControlFlag (", stdout);
#line 180 "Terminal.hsc"
    hsc_const (PARENB);
    fputs (") termios\n"
           "", stdout);
    hsc_line (181, "Terminal.hsc");
    fputs ("withMode termios OddParity = setControlFlag (", stdout);
#line 181 "Terminal.hsc"
    hsc_const (PARODD);
    fputs (") termios\n"
           "", stdout);
    hsc_line (182, "Terminal.hsc");
    fputs ("withMode termios EnableEcho = setLocalFlag (", stdout);
#line 182 "Terminal.hsc"
    hsc_const (ECHO);
    fputs (") termios\n"
           "", stdout);
    hsc_line (183, "Terminal.hsc");
    fputs ("withMode termios EchoErase = setLocalFlag (", stdout);
#line 183 "Terminal.hsc"
    hsc_const (ECHOE);
    fputs (") termios\n"
           "", stdout);
    hsc_line (184, "Terminal.hsc");
    fputs ("withMode termios EchoKill = setLocalFlag (", stdout);
#line 184 "Terminal.hsc"
    hsc_const (ECHOK);
    fputs (") termios\n"
           "", stdout);
    hsc_line (185, "Terminal.hsc");
    fputs ("withMode termios EchoLF = setLocalFlag (", stdout);
#line 185 "Terminal.hsc"
    hsc_const (ECHONL);
    fputs (") termios\n"
           "", stdout);
    hsc_line (186, "Terminal.hsc");
    fputs ("withMode termios ProcessInput = setLocalFlag (", stdout);
#line 186 "Terminal.hsc"
    hsc_const (ICANON);
    fputs (") termios\n"
           "", stdout);
    hsc_line (187, "Terminal.hsc");
    fputs ("withMode termios ExtendedFunctions = setLocalFlag (", stdout);
#line 187 "Terminal.hsc"
    hsc_const (IEXTEN);
    fputs (") termios\n"
           "", stdout);
    hsc_line (188, "Terminal.hsc");
    fputs ("withMode termios KeyboardInterrupts = setLocalFlag (", stdout);
#line 188 "Terminal.hsc"
    hsc_const (ISIG);
    fputs (") termios\n"
           "", stdout);
    hsc_line (189, "Terminal.hsc");
    fputs ("withMode termios NoFlushOnInterrupt = clearLocalFlag (", stdout);
#line 189 "Terminal.hsc"
    hsc_const (NOFLSH);
    fputs (") termios\n"
           "", stdout);
    hsc_line (190, "Terminal.hsc");
    fputs ("withMode termios BackgroundWriteInterrupt = setLocalFlag (", stdout);
#line 190 "Terminal.hsc"
    hsc_const (TOSTOP);
    fputs (") termios\n"
           "", stdout);
    hsc_line (191, "Terminal.hsc");
    fputs ("\n"
           "terminalMode :: TerminalMode -> TerminalAttributes -> Bool\n"
           "terminalMode InterruptOnBreak = testInputFlag (", stdout);
#line 193 "Terminal.hsc"
    hsc_const (BRKINT);
    fputs (")\n"
           "", stdout);
    hsc_line (194, "Terminal.hsc");
    fputs ("terminalMode MapCRtoLF = testInputFlag (", stdout);
#line 194 "Terminal.hsc"
    hsc_const (ICRNL);
    fputs (")\n"
           "", stdout);
    hsc_line (195, "Terminal.hsc");
    fputs ("terminalMode IgnoreBreak = testInputFlag (", stdout);
#line 195 "Terminal.hsc"
    hsc_const (IGNBRK);
    fputs (")\n"
           "", stdout);
    hsc_line (196, "Terminal.hsc");
    fputs ("terminalMode IgnoreCR = testInputFlag (", stdout);
#line 196 "Terminal.hsc"
    hsc_const (IGNCR);
    fputs (")\n"
           "", stdout);
    hsc_line (197, "Terminal.hsc");
    fputs ("terminalMode IgnoreParityErrors = testInputFlag (", stdout);
#line 197 "Terminal.hsc"
    hsc_const (IGNPAR);
    fputs (")\n"
           "", stdout);
    hsc_line (198, "Terminal.hsc");
    fputs ("terminalMode MapLFtoCR = testInputFlag (", stdout);
#line 198 "Terminal.hsc"
    hsc_const (INLCR);
    fputs (")\n"
           "", stdout);
    hsc_line (199, "Terminal.hsc");
    fputs ("terminalMode CheckParity = testInputFlag (", stdout);
#line 199 "Terminal.hsc"
    hsc_const (INPCK);
    fputs (")\n"
           "", stdout);
    hsc_line (200, "Terminal.hsc");
    fputs ("terminalMode StripHighBit = testInputFlag (", stdout);
#line 200 "Terminal.hsc"
    hsc_const (ISTRIP);
    fputs (")\n"
           "", stdout);
    hsc_line (201, "Terminal.hsc");
    fputs ("terminalMode StartStopInput = testInputFlag (", stdout);
#line 201 "Terminal.hsc"
    hsc_const (IXOFF);
    fputs (")\n"
           "", stdout);
    hsc_line (202, "Terminal.hsc");
    fputs ("terminalMode StartStopOutput = testInputFlag (", stdout);
#line 202 "Terminal.hsc"
    hsc_const (IXON);
    fputs (")\n"
           "", stdout);
    hsc_line (203, "Terminal.hsc");
    fputs ("terminalMode MarkParityErrors = testInputFlag (", stdout);
#line 203 "Terminal.hsc"
    hsc_const (PARMRK);
    fputs (")\n"
           "", stdout);
    hsc_line (204, "Terminal.hsc");
    fputs ("terminalMode ProcessOutput = testOutputFlag (", stdout);
#line 204 "Terminal.hsc"
    hsc_const (OPOST);
    fputs (")\n"
           "", stdout);
    hsc_line (205, "Terminal.hsc");
    fputs ("terminalMode LocalMode = testControlFlag (", stdout);
#line 205 "Terminal.hsc"
    hsc_const (CLOCAL);
    fputs (")\n"
           "", stdout);
    hsc_line (206, "Terminal.hsc");
    fputs ("terminalMode ReadEnable = testControlFlag (", stdout);
#line 206 "Terminal.hsc"
    hsc_const (CREAD);
    fputs (")\n"
           "", stdout);
    hsc_line (207, "Terminal.hsc");
    fputs ("terminalMode TwoStopBits = testControlFlag (", stdout);
#line 207 "Terminal.hsc"
    hsc_const (CSTOPB);
    fputs (")\n"
           "", stdout);
    hsc_line (208, "Terminal.hsc");
    fputs ("terminalMode HangupOnClose = testControlFlag (", stdout);
#line 208 "Terminal.hsc"
    hsc_const (HUPCL);
    fputs (")\n"
           "", stdout);
    hsc_line (209, "Terminal.hsc");
    fputs ("terminalMode EnableParity = testControlFlag (", stdout);
#line 209 "Terminal.hsc"
    hsc_const (PARENB);
    fputs (")\n"
           "", stdout);
    hsc_line (210, "Terminal.hsc");
    fputs ("terminalMode OddParity = testControlFlag (", stdout);
#line 210 "Terminal.hsc"
    hsc_const (PARODD);
    fputs (")\n"
           "", stdout);
    hsc_line (211, "Terminal.hsc");
    fputs ("terminalMode EnableEcho = testLocalFlag (", stdout);
#line 211 "Terminal.hsc"
    hsc_const (ECHO);
    fputs (")\n"
           "", stdout);
    hsc_line (212, "Terminal.hsc");
    fputs ("terminalMode EchoErase = testLocalFlag (", stdout);
#line 212 "Terminal.hsc"
    hsc_const (ECHOE);
    fputs (")\n"
           "", stdout);
    hsc_line (213, "Terminal.hsc");
    fputs ("terminalMode EchoKill = testLocalFlag (", stdout);
#line 213 "Terminal.hsc"
    hsc_const (ECHOK);
    fputs (")\n"
           "", stdout);
    hsc_line (214, "Terminal.hsc");
    fputs ("terminalMode EchoLF = testLocalFlag (", stdout);
#line 214 "Terminal.hsc"
    hsc_const (ECHONL);
    fputs (")\n"
           "", stdout);
    hsc_line (215, "Terminal.hsc");
    fputs ("terminalMode ProcessInput = testLocalFlag (", stdout);
#line 215 "Terminal.hsc"
    hsc_const (ICANON);
    fputs (")\n"
           "", stdout);
    hsc_line (216, "Terminal.hsc");
    fputs ("terminalMode ExtendedFunctions = testLocalFlag (", stdout);
#line 216 "Terminal.hsc"
    hsc_const (IEXTEN);
    fputs (")\n"
           "", stdout);
    hsc_line (217, "Terminal.hsc");
    fputs ("terminalMode KeyboardInterrupts = testLocalFlag (", stdout);
#line 217 "Terminal.hsc"
    hsc_const (ISIG);
    fputs (")\n"
           "", stdout);
    hsc_line (218, "Terminal.hsc");
    fputs ("terminalMode NoFlushOnInterrupt = not . testLocalFlag (", stdout);
#line 218 "Terminal.hsc"
    hsc_const (NOFLSH);
    fputs (")\n"
           "", stdout);
    hsc_line (219, "Terminal.hsc");
    fputs ("terminalMode BackgroundWriteInterrupt = testLocalFlag (", stdout);
#line 219 "Terminal.hsc"
    hsc_const (TOSTOP);
    fputs (")\n"
           "", stdout);
    hsc_line (220, "Terminal.hsc");
    fputs ("\n"
           "bitsPerByte :: TerminalAttributes -> Int\n"
           "bitsPerByte termios = unsafePerformIO $ do\n"
           "  withTerminalAttributes termios $ \\p -> do\n"
           "    cflag <- (", stdout);
#line 224 "Terminal.hsc"
    hsc_peek (struct termios, c_cflag);
    fputs (") p\n"
           "", stdout);
    hsc_line (225, "Terminal.hsc");
    fputs ("    return $! (word2Bits (cflag .&. (", stdout);
#line 225 "Terminal.hsc"
    hsc_const (CSIZE);
    fputs (")))\n"
           "", stdout);
    hsc_line (226, "Terminal.hsc");
    fputs ("  where\n"
           "    word2Bits :: CTcflag -> Int\n"
           "    word2Bits x =\n"
           "\tif x == (", stdout);
#line 229 "Terminal.hsc"
    hsc_const (CS5);
    fputs (") then 5\n"
           "", stdout);
    hsc_line (230, "Terminal.hsc");
    fputs ("\telse if x == (", stdout);
#line 230 "Terminal.hsc"
    hsc_const (CS6);
    fputs (") then 6\n"
           "", stdout);
    hsc_line (231, "Terminal.hsc");
    fputs ("\telse if x == (", stdout);
#line 231 "Terminal.hsc"
    hsc_const (CS7);
    fputs (") then 7\n"
           "", stdout);
    hsc_line (232, "Terminal.hsc");
    fputs ("\telse if x == (", stdout);
#line 232 "Terminal.hsc"
    hsc_const (CS8);
    fputs (") then 8\n"
           "", stdout);
    hsc_line (233, "Terminal.hsc");
    fputs ("\telse 0\n"
           "\n"
           "withBits :: TerminalAttributes -> Int -> TerminalAttributes\n"
           "withBits termios bits = unsafePerformIO $ do\n"
           "  withNewTermios termios $ \\p -> do\n"
           "    cflag <- (", stdout);
#line 238 "Terminal.hsc"
    hsc_peek (struct termios, c_cflag);
    fputs (") p\n"
           "", stdout);
    hsc_line (239, "Terminal.hsc");
    fputs ("    (", stdout);
#line 239 "Terminal.hsc"
    hsc_poke (struct termios, c_cflag);
    fputs (") p\n"
           "", stdout);
    hsc_line (240, "Terminal.hsc");
    fputs ("       ((cflag .&. complement (", stdout);
#line 240 "Terminal.hsc"
    hsc_const (CSIZE);
    fputs (")) .|. mask bits)\n"
           "", stdout);
    hsc_line (241, "Terminal.hsc");
    fputs ("  where\n"
           "    mask :: Int -> CTcflag\n"
           "    mask 5 = (", stdout);
#line 243 "Terminal.hsc"
    hsc_const (CS5);
    fputs (")\n"
           "", stdout);
    hsc_line (244, "Terminal.hsc");
    fputs ("    mask 6 = (", stdout);
#line 244 "Terminal.hsc"
    hsc_const (CS6);
    fputs (")\n"
           "", stdout);
    hsc_line (245, "Terminal.hsc");
    fputs ("    mask 7 = (", stdout);
#line 245 "Terminal.hsc"
    hsc_const (CS7);
    fputs (")\n"
           "", stdout);
    hsc_line (246, "Terminal.hsc");
    fputs ("    mask 8 = (", stdout);
#line 246 "Terminal.hsc"
    hsc_const (CS8);
    fputs (")\n"
           "", stdout);
    hsc_line (247, "Terminal.hsc");
    fputs ("    mask _ = error \"withBits bit value out of range [5..8]\"\n"
           "\n"
           "data ControlCharacter\n"
           "  = EndOfFile\t\t-- VEOF\n"
           "  | EndOfLine\t\t-- VEOL\n"
           "  | Erase\t\t-- VERASE\n"
           "  | Interrupt\t\t-- VINTR\n"
           "  | Kill\t\t-- VKILL\n"
           "  | Quit\t\t-- VQUIT\n"
           "  | Start\t\t-- VSTART\n"
           "  | Stop\t\t-- VSTOP\n"
           "  | Suspend\t\t-- VSUSP\n"
           "\n"
           "controlChar :: TerminalAttributes -> ControlCharacter -> Maybe Char\n"
           "controlChar termios cc = unsafePerformIO $ do\n"
           "  withTerminalAttributes termios $ \\p -> do\n"
           "    let c_cc = (", stdout);
#line 263 "Terminal.hsc"
    hsc_ptr (struct termios, c_cc);
    fputs (") p\n"
           "", stdout);
    hsc_line (264, "Terminal.hsc");
    fputs ("    val <- peekElemOff c_cc (cc2Word cc)\n"
           "    if val == ((", stdout);
#line 265 "Terminal.hsc"
    hsc_const (_POSIX_VDISABLE);
    fputs (")::CCc)\n"
           "", stdout);
    hsc_line (266, "Terminal.hsc");
    fputs ("       then return Nothing\n"
           "       else return (Just (chr (fromEnum val)))\n"
           "  \n"
           "withCC :: TerminalAttributes\n"
           "       -> (ControlCharacter, Char)\n"
           "       -> TerminalAttributes\n"
           "withCC termios (cc, c) = unsafePerformIO $ do\n"
           "  withNewTermios termios $ \\p -> do\n"
           "    let c_cc = (", stdout);
#line 274 "Terminal.hsc"
    hsc_ptr (struct termios, c_cc);
    fputs (") p\n"
           "", stdout);
    hsc_line (275, "Terminal.hsc");
    fputs ("    pokeElemOff c_cc (cc2Word cc) (fromIntegral (ord c) :: CCc)\n"
           "\n"
           "withoutCC :: TerminalAttributes\n"
           "          -> ControlCharacter\n"
           "          -> TerminalAttributes\n"
           "withoutCC termios cc = unsafePerformIO $ do\n"
           "  withNewTermios termios $ \\p -> do\n"
           "    let c_cc = (", stdout);
#line 282 "Terminal.hsc"
    hsc_ptr (struct termios, c_cc);
    fputs (") p\n"
           "", stdout);
    hsc_line (283, "Terminal.hsc");
    fputs ("    pokeElemOff c_cc (cc2Word cc) ((", stdout);
#line 283 "Terminal.hsc"
    hsc_const (_POSIX_VDISABLE);
    fputs (") :: CCc)\n"
           "", stdout);
    hsc_line (284, "Terminal.hsc");
    fputs ("\n"
           "inputTime :: TerminalAttributes -> Int\n"
           "inputTime termios = unsafePerformIO $ do\n"
           "  withTerminalAttributes termios $ \\p -> do\n"
           "    c <- peekElemOff ((", stdout);
#line 288 "Terminal.hsc"
    hsc_ptr (struct termios, c_cc);
    fputs (") p) (", stdout);
#line 288 "Terminal.hsc"
    hsc_const (VTIME);
    fputs (")\n"
           "", stdout);
    hsc_line (289, "Terminal.hsc");
    fputs ("    return (fromEnum (c :: CCc))\n"
           "\n"
           "withTime :: TerminalAttributes -> Int -> TerminalAttributes\n"
           "withTime termios time = unsafePerformIO $ do\n"
           "  withNewTermios termios $ \\p -> do\n"
           "    let c_cc = (", stdout);
#line 294 "Terminal.hsc"
    hsc_ptr (struct termios, c_cc);
    fputs (") p\n"
           "", stdout);
    hsc_line (295, "Terminal.hsc");
    fputs ("    pokeElemOff c_cc (", stdout);
#line 295 "Terminal.hsc"
    hsc_const (VTIME);
    fputs (") (fromIntegral time :: CCc)\n"
           "", stdout);
    hsc_line (296, "Terminal.hsc");
    fputs ("\n"
           "minInput :: TerminalAttributes -> Int\n"
           "minInput termios = unsafePerformIO $ do\n"
           "  withTerminalAttributes termios $ \\p -> do\n"
           "    c <- peekElemOff ((", stdout);
#line 300 "Terminal.hsc"
    hsc_ptr (struct termios, c_cc);
    fputs (") p) (", stdout);
#line 300 "Terminal.hsc"
    hsc_const (VMIN);
    fputs (")\n"
           "", stdout);
    hsc_line (301, "Terminal.hsc");
    fputs ("    return (fromEnum (c :: CCc))\n"
           "\n"
           "withMinInput :: TerminalAttributes -> Int -> TerminalAttributes\n"
           "withMinInput termios count = unsafePerformIO $ do\n"
           "  withNewTermios termios $ \\p -> do\n"
           "    let c_cc = (", stdout);
#line 306 "Terminal.hsc"
    hsc_ptr (struct termios, c_cc);
    fputs (") p\n"
           "", stdout);
    hsc_line (307, "Terminal.hsc");
    fputs ("    pokeElemOff c_cc (", stdout);
#line 307 "Terminal.hsc"
    hsc_const (VMIN);
    fputs (") (fromIntegral count :: CCc)\n"
           "", stdout);
    hsc_line (308, "Terminal.hsc");
    fputs ("\n"
           "data BaudRate\n"
           "  = B0\n"
           "  | B50\n"
           "  | B75\n"
           "  | B110\n"
           "  | B134\n"
           "  | B150\n"
           "  | B200\n"
           "  | B300\n"
           "  | B600\n"
           "  | B1200\n"
           "  | B1800\n"
           "  | B2400\n"
           "  | B4800\n"
           "  | B9600\n"
           "  | B19200\n"
           "  | B38400\n"
           "\n"
           "inputSpeed :: TerminalAttributes -> BaudRate\n"
           "inputSpeed termios = unsafePerformIO $ do\n"
           "  withTerminalAttributes termios $ \\p -> do\n"
           "    w <- c_cfgetispeed p\n"
           "    return (word2Baud w)\n"
           "\n"
           "foreign import ccall unsafe \"cfgetispeed\"\n"
           "  c_cfgetispeed :: Ptr CTermios -> IO CSpeed\n"
           "\n"
           "withInputSpeed :: TerminalAttributes -> BaudRate -> TerminalAttributes\n"
           "withInputSpeed termios br = unsafePerformIO $ do\n"
           "  withNewTermios termios $ \\p -> c_cfsetispeed p (baud2Word br)\n"
           "\n"
           "foreign import ccall unsafe \"cfsetispeed\"\n"
           "  c_cfsetispeed :: Ptr CTermios -> CSpeed -> IO CInt\n"
           "\n"
           "\n"
           "outputSpeed :: TerminalAttributes -> BaudRate\n"
           "outputSpeed termios = unsafePerformIO $ do\n"
           "  withTerminalAttributes termios $ \\p ->  do\n"
           "    w <- c_cfgetospeed p\n"
           "    return (word2Baud w)\n"
           "\n"
           "foreign import ccall unsafe \"cfgetospeed\"\n"
           "  c_cfgetospeed :: Ptr CTermios -> IO CSpeed\n"
           "\n"
           "withOutputSpeed :: TerminalAttributes -> BaudRate -> TerminalAttributes\n"
           "withOutputSpeed termios br = unsafePerformIO $ do\n"
           "  withNewTermios termios $ \\p -> c_cfsetospeed p (baud2Word br)\n"
           "\n"
           "foreign import ccall unsafe \"cfsetospeed\"\n"
           "  c_cfsetospeed :: Ptr CTermios -> CSpeed -> IO CInt\n"
           "\n"
           "\n"
           "getTerminalAttributes :: Fd -> IO TerminalAttributes\n"
           "getTerminalAttributes fd = do\n"
           "  fp <- mallocForeignPtrBytes (", stdout);
#line 363 "Terminal.hsc"
    hsc_const (sizeof(struct termios));
    fputs (")\n"
           "", stdout);
    hsc_line (364, "Terminal.hsc");
    fputs ("  withForeignPtr fp $ \\p ->\n"
           "      throwErrnoIfMinus1_ \"getTerminalAttributes\" (c_tcgetattr fd p)\n"
           "  return $ makeTerminalAttributes fp\n"
           "\n"
           "foreign import ccall unsafe \"tcgetattr\"\n"
           "  c_tcgetattr :: Fd -> Ptr CTermios -> IO CInt\n"
           "\n"
           "data TerminalState\n"
           "  = Immediately\n"
           "  | WhenDrained\n"
           "  | WhenFlushed\n"
           "\n"
           "setTerminalAttributes :: Fd\n"
           "                      -> TerminalAttributes\n"
           "                      -> TerminalState\n"
           "                      -> IO ()\n"
           "setTerminalAttributes fd termios state = do\n"
           "  withTerminalAttributes termios $ \\p ->\n"
           "    throwErrnoIfMinus1_ \"setTerminalAttributes\"\n"
           "      (c_tcsetattr fd (state2Int state) p)\n"
           "  where\n"
           "    state2Int :: TerminalState -> CInt\n"
           "    state2Int Immediately = (", stdout);
#line 386 "Terminal.hsc"
    hsc_const (TCSANOW);
    fputs (")\n"
           "", stdout);
    hsc_line (387, "Terminal.hsc");
    fputs ("    state2Int WhenDrained = (", stdout);
#line 387 "Terminal.hsc"
    hsc_const (TCSADRAIN);
    fputs (")\n"
           "", stdout);
    hsc_line (388, "Terminal.hsc");
    fputs ("    state2Int WhenFlushed = (", stdout);
#line 388 "Terminal.hsc"
    hsc_const (TCSAFLUSH);
    fputs (")\n"
           "", stdout);
    hsc_line (389, "Terminal.hsc");
    fputs ("\n"
           "foreign import ccall unsafe \"tcsetattr\"\n"
           "   c_tcsetattr :: Fd -> CInt -> Ptr CTermios -> IO CInt\n"
           "\n"
           "\n"
           "sendBreak :: Fd -> Int -> IO ()\n"
           "sendBreak fd duration\n"
           "  = throwErrnoIfMinus1_ \"sendBreak\" (c_tcsendbreak fd (fromIntegral duration))\n"
           "\n"
           "foreign import ccall unsafe \"tcsendbreak\"\n"
           "  c_tcsendbreak :: Fd -> CInt -> IO CInt\n"
           "\n"
           "drainOutput :: Fd -> IO ()\n"
           "drainOutput fd = throwErrnoIfMinus1_ \"drainOutput\" (c_tcdrain fd)\n"
           "\n"
           "foreign import ccall unsafe \"tcdrain\"\n"
           "  c_tcdrain :: Fd -> IO CInt\n"
           "\n"
           "\n"
           "data QueueSelector\n"
           "  = InputQueue\t\t-- TCIFLUSH\n"
           "  | OutputQueue\t\t-- TCOFLUSH\n"
           "  | BothQueues\t\t-- TCIOFLUSH\n"
           "\n"
           "discardData :: Fd -> QueueSelector -> IO ()\n"
           "discardData fd queue =\n"
           "  throwErrnoIfMinus1_ \"discardData\" (c_tcflush fd (queue2Int queue))\n"
           "  where\n"
           "    queue2Int :: QueueSelector -> CInt\n"
           "    queue2Int InputQueue  = (", stdout);
#line 418 "Terminal.hsc"
    hsc_const (TCIFLUSH);
    fputs (")\n"
           "", stdout);
    hsc_line (419, "Terminal.hsc");
    fputs ("    queue2Int OutputQueue = (", stdout);
#line 419 "Terminal.hsc"
    hsc_const (TCOFLUSH);
    fputs (")\n"
           "", stdout);
    hsc_line (420, "Terminal.hsc");
    fputs ("    queue2Int BothQueues  = (", stdout);
#line 420 "Terminal.hsc"
    hsc_const (TCIOFLUSH);
    fputs (")\n"
           "", stdout);
    hsc_line (421, "Terminal.hsc");
    fputs ("\n"
           "foreign import ccall unsafe \"tcflush\"\n"
           "  c_tcflush :: Fd -> CInt -> IO CInt\n"
           "\n"
           "data FlowAction\n"
           "  = SuspendOutput\t-- TCOOFF\n"
           "  | RestartOutput\t-- TCOON\n"
           "  | TransmitStop\t-- TCIOFF\n"
           "  | TransmitStart\t-- TCION\n"
           "\n"
           "controlFlow :: Fd -> FlowAction -> IO ()\n"
           "controlFlow fd action =\n"
           "  throwErrnoIfMinus1_ \"controlFlow\" (c_tcflow fd (action2Int action))\n"
           "  where\n"
           "    action2Int :: FlowAction -> CInt\n"
           "    action2Int SuspendOutput = (", stdout);
#line 436 "Terminal.hsc"
    hsc_const (TCOOFF);
    fputs (")\n"
           "", stdout);
    hsc_line (437, "Terminal.hsc");
    fputs ("    action2Int RestartOutput = (", stdout);
#line 437 "Terminal.hsc"
    hsc_const (TCOON);
    fputs (")\n"
           "", stdout);
    hsc_line (438, "Terminal.hsc");
    fputs ("    action2Int TransmitStop  = (", stdout);
#line 438 "Terminal.hsc"
    hsc_const (TCIOFF);
    fputs (")\n"
           "", stdout);
    hsc_line (439, "Terminal.hsc");
    fputs ("    action2Int TransmitStart = (", stdout);
#line 439 "Terminal.hsc"
    hsc_const (TCION);
    fputs (")\n"
           "", stdout);
    hsc_line (440, "Terminal.hsc");
    fputs ("\n"
           "foreign import ccall unsafe \"tcflow\"\n"
           "  c_tcflow :: Fd -> CInt -> IO CInt\n"
           "\n"
           "getTerminalProcessGroupID :: Fd -> IO ProcessGroupID\n"
           "getTerminalProcessGroupID fd = do\n"
           "  throwErrnoIfMinus1 \"getTerminalProcessGroupID\" (c_tcgetpgrp fd)\n"
           "\n"
           "foreign import ccall unsafe \"tcgetpgrp\"\n"
           "  c_tcgetpgrp :: Fd -> IO CPid\n"
           "\n"
           "setTerminalProcessGroupID :: Fd -> ProcessGroupID -> IO ()\n"
           "setTerminalProcessGroupID fd pgid =\n"
           "  throwErrnoIfMinus1_ \"setTerminalProcessGroupID\" (c_tcsetpgrp fd pgid)\n"
           "\n"
           "foreign import ccall unsafe \"tcsetpgrp\"\n"
           "  c_tcsetpgrp :: Fd -> CPid -> IO CInt\n"
           "\n"
           "-- -----------------------------------------------------------------------------\n"
           "-- file descriptor queries\n"
           "\n"
           "queryTerminal :: Fd -> IO Bool\n"
           "queryTerminal fd = do\n"
           "  r <- c_isatty fd\n"
           "  return (r == 1)\n"
           "  -- ToDo: the spec says that it can set errno to EBADF if the result is zero\n"
           "\n"
           "foreign import ccall unsafe \"isatty\"\n"
           "  c_isatty :: Fd -> IO CInt\n"
           "\n"
           "\n"
           "getTerminalName :: Fd -> IO FilePath\n"
           "getTerminalName fd = do\n"
           "  s <- throwErrnoIfNull \"getTerminalName\" (c_ttyname fd)\n"
           "  peekCString s  \n"
           "\n"
           "foreign import ccall unsafe \"ttyname\"\n"
           "  c_ttyname :: Fd -> IO CString\n"
           "\n"
           "getControllingTerminalName :: IO FilePath\n"
           "getControllingTerminalName = do\n"
           "  s <- throwErrnoIfNull \"getControllingTerminalName\" (c_ctermid nullPtr)\n"
           "  peekCString s\n"
           "\n"
           "foreign import ccall unsafe \"ctermid\"\n"
           "  c_ctermid :: CString -> IO CString\n"
           "\n"
           "-- -----------------------------------------------------------------------------\n"
           "-- Local utility functions\n"
           "\n"
           "-- Convert Haskell ControlCharacter to Int\n"
           "\n"
           "cc2Word :: ControlCharacter -> Int\n"
           "cc2Word EndOfFile = (", stdout);
#line 493 "Terminal.hsc"
    hsc_const (VEOF);
    fputs (")\n"
           "", stdout);
    hsc_line (494, "Terminal.hsc");
    fputs ("cc2Word EndOfLine = (", stdout);
#line 494 "Terminal.hsc"
    hsc_const (VEOL);
    fputs (")\n"
           "", stdout);
    hsc_line (495, "Terminal.hsc");
    fputs ("cc2Word Erase     = (", stdout);
#line 495 "Terminal.hsc"
    hsc_const (VERASE);
    fputs (")\n"
           "", stdout);
    hsc_line (496, "Terminal.hsc");
    fputs ("cc2Word Interrupt = (", stdout);
#line 496 "Terminal.hsc"
    hsc_const (VINTR);
    fputs (")\n"
           "", stdout);
    hsc_line (497, "Terminal.hsc");
    fputs ("cc2Word Kill      = (", stdout);
#line 497 "Terminal.hsc"
    hsc_const (VKILL);
    fputs (")\n"
           "", stdout);
    hsc_line (498, "Terminal.hsc");
    fputs ("cc2Word Quit      = (", stdout);
#line 498 "Terminal.hsc"
    hsc_const (VQUIT);
    fputs (")\n"
           "", stdout);
    hsc_line (499, "Terminal.hsc");
    fputs ("cc2Word Suspend   = (", stdout);
#line 499 "Terminal.hsc"
    hsc_const (VSUSP);
    fputs (")\n"
           "", stdout);
    hsc_line (500, "Terminal.hsc");
    fputs ("cc2Word Start     = (", stdout);
#line 500 "Terminal.hsc"
    hsc_const (VSTART);
    fputs (")\n"
           "", stdout);
    hsc_line (501, "Terminal.hsc");
    fputs ("cc2Word Stop      = (", stdout);
#line 501 "Terminal.hsc"
    hsc_const (VSTOP);
    fputs (")\n"
           "", stdout);
    hsc_line (502, "Terminal.hsc");
    fputs ("\n"
           "-- Convert Haskell BaudRate to unsigned integral type (Word)\n"
           "\n"
           "baud2Word :: BaudRate -> CSpeed\n"
           "baud2Word B0 = (", stdout);
#line 506 "Terminal.hsc"
    hsc_const (B0);
    fputs (")\n"
           "", stdout);
    hsc_line (507, "Terminal.hsc");
    fputs ("baud2Word B50 = (", stdout);
#line 507 "Terminal.hsc"
    hsc_const (B50);
    fputs (")\n"
           "", stdout);
    hsc_line (508, "Terminal.hsc");
    fputs ("baud2Word B75 = (", stdout);
#line 508 "Terminal.hsc"
    hsc_const (B75);
    fputs (")\n"
           "", stdout);
    hsc_line (509, "Terminal.hsc");
    fputs ("baud2Word B110 = (", stdout);
#line 509 "Terminal.hsc"
    hsc_const (B110);
    fputs (")\n"
           "", stdout);
    hsc_line (510, "Terminal.hsc");
    fputs ("baud2Word B134 = (", stdout);
#line 510 "Terminal.hsc"
    hsc_const (B134);
    fputs (")\n"
           "", stdout);
    hsc_line (511, "Terminal.hsc");
    fputs ("baud2Word B150 = (", stdout);
#line 511 "Terminal.hsc"
    hsc_const (B150);
    fputs (")\n"
           "", stdout);
    hsc_line (512, "Terminal.hsc");
    fputs ("baud2Word B200 = (", stdout);
#line 512 "Terminal.hsc"
    hsc_const (B200);
    fputs (")\n"
           "", stdout);
    hsc_line (513, "Terminal.hsc");
    fputs ("baud2Word B300 = (", stdout);
#line 513 "Terminal.hsc"
    hsc_const (B300);
    fputs (")\n"
           "", stdout);
    hsc_line (514, "Terminal.hsc");
    fputs ("baud2Word B600 = (", stdout);
#line 514 "Terminal.hsc"
    hsc_const (B600);
    fputs (")\n"
           "", stdout);
    hsc_line (515, "Terminal.hsc");
    fputs ("baud2Word B1200 = (", stdout);
#line 515 "Terminal.hsc"
    hsc_const (B1200);
    fputs (")\n"
           "", stdout);
    hsc_line (516, "Terminal.hsc");
    fputs ("baud2Word B1800 = (", stdout);
#line 516 "Terminal.hsc"
    hsc_const (B1800);
    fputs (")\n"
           "", stdout);
    hsc_line (517, "Terminal.hsc");
    fputs ("baud2Word B2400 = (", stdout);
#line 517 "Terminal.hsc"
    hsc_const (B2400);
    fputs (")\n"
           "", stdout);
    hsc_line (518, "Terminal.hsc");
    fputs ("baud2Word B4800 = (", stdout);
#line 518 "Terminal.hsc"
    hsc_const (B4800);
    fputs (")\n"
           "", stdout);
    hsc_line (519, "Terminal.hsc");
    fputs ("baud2Word B9600 = (", stdout);
#line 519 "Terminal.hsc"
    hsc_const (B9600);
    fputs (")\n"
           "", stdout);
    hsc_line (520, "Terminal.hsc");
    fputs ("baud2Word B19200 = (", stdout);
#line 520 "Terminal.hsc"
    hsc_const (B19200);
    fputs (")\n"
           "", stdout);
    hsc_line (521, "Terminal.hsc");
    fputs ("baud2Word B38400 = (", stdout);
#line 521 "Terminal.hsc"
    hsc_const (B38400);
    fputs (")\n"
           "", stdout);
    hsc_line (522, "Terminal.hsc");
    fputs ("\n"
           "-- And convert a word back to a baud rate\n"
           "-- We really need some cpp macros here.\n"
           "\n"
           "word2Baud :: CSpeed -> BaudRate\n"
           "word2Baud x =\n"
           "    if x == (", stdout);
#line 528 "Terminal.hsc"
    hsc_const (B0);
    fputs (") then B0\n"
           "", stdout);
    hsc_line (529, "Terminal.hsc");
    fputs ("    else if x == (", stdout);
#line 529 "Terminal.hsc"
    hsc_const (B50);
    fputs (") then B50\n"
           "", stdout);
    hsc_line (530, "Terminal.hsc");
    fputs ("    else if x == (", stdout);
#line 530 "Terminal.hsc"
    hsc_const (B75);
    fputs (") then B75\n"
           "", stdout);
    hsc_line (531, "Terminal.hsc");
    fputs ("    else if x == (", stdout);
#line 531 "Terminal.hsc"
    hsc_const (B110);
    fputs (") then B110\n"
           "", stdout);
    hsc_line (532, "Terminal.hsc");
    fputs ("    else if x == (", stdout);
#line 532 "Terminal.hsc"
    hsc_const (B134);
    fputs (") then B134\n"
           "", stdout);
    hsc_line (533, "Terminal.hsc");
    fputs ("    else if x == (", stdout);
#line 533 "Terminal.hsc"
    hsc_const (B150);
    fputs (") then B150\n"
           "", stdout);
    hsc_line (534, "Terminal.hsc");
    fputs ("    else if x == (", stdout);
#line 534 "Terminal.hsc"
    hsc_const (B200);
    fputs (") then B200\n"
           "", stdout);
    hsc_line (535, "Terminal.hsc");
    fputs ("    else if x == (", stdout);
#line 535 "Terminal.hsc"
    hsc_const (B300);
    fputs (") then B300\n"
           "", stdout);
    hsc_line (536, "Terminal.hsc");
    fputs ("    else if x == (", stdout);
#line 536 "Terminal.hsc"
    hsc_const (B600);
    fputs (") then B600\n"
           "", stdout);
    hsc_line (537, "Terminal.hsc");
    fputs ("    else if x == (", stdout);
#line 537 "Terminal.hsc"
    hsc_const (B1200);
    fputs (") then B1200\n"
           "", stdout);
    hsc_line (538, "Terminal.hsc");
    fputs ("    else if x == (", stdout);
#line 538 "Terminal.hsc"
    hsc_const (B1800);
    fputs (") then B1800\n"
           "", stdout);
    hsc_line (539, "Terminal.hsc");
    fputs ("    else if x == (", stdout);
#line 539 "Terminal.hsc"
    hsc_const (B2400);
    fputs (") then B2400\n"
           "", stdout);
    hsc_line (540, "Terminal.hsc");
    fputs ("    else if x == (", stdout);
#line 540 "Terminal.hsc"
    hsc_const (B4800);
    fputs (") then B4800\n"
           "", stdout);
    hsc_line (541, "Terminal.hsc");
    fputs ("    else if x == (", stdout);
#line 541 "Terminal.hsc"
    hsc_const (B9600);
    fputs (") then B9600\n"
           "", stdout);
    hsc_line (542, "Terminal.hsc");
    fputs ("    else if x == (", stdout);
#line 542 "Terminal.hsc"
    hsc_const (B19200);
    fputs (") then B19200\n"
           "", stdout);
    hsc_line (543, "Terminal.hsc");
    fputs ("    else if x == (", stdout);
#line 543 "Terminal.hsc"
    hsc_const (B38400);
    fputs (") then B38400\n"
           "", stdout);
    hsc_line (544, "Terminal.hsc");
    fputs ("    else error \"unknown baud rate\"\n"
           "\n"
           "-- Clear termios i_flag\n"
           "\n"
           "clearInputFlag :: CTcflag -> TerminalAttributes -> TerminalAttributes\n"
           "clearInputFlag flag termios = unsafePerformIO $ do\n"
           "  fp <- mallocForeignPtrBytes (", stdout);
#line 550 "Terminal.hsc"
    hsc_const (sizeof(struct termios));
    fputs (")\n"
           "", stdout);
    hsc_line (551, "Terminal.hsc");
    fputs ("  withForeignPtr fp $ \\p1 -> do\n"
           "    withTerminalAttributes termios $ \\p2 -> do\n"
           "      copyBytes p1 p2 (", stdout);
#line 553 "Terminal.hsc"
    hsc_const (sizeof(struct termios));
    fputs (") \n"
           "", stdout);
    hsc_line (554, "Terminal.hsc");
    fputs ("      iflag <- (", stdout);
#line 554 "Terminal.hsc"
    hsc_peek (struct termios, c_iflag);
    fputs (") p2\n"
           "", stdout);
    hsc_line (555, "Terminal.hsc");
    fputs ("      (", stdout);
#line 555 "Terminal.hsc"
    hsc_poke (struct termios, c_iflag);
    fputs (") p1 (iflag .&. complement flag)\n"
           "", stdout);
    hsc_line (556, "Terminal.hsc");
    fputs ("  return $ makeTerminalAttributes fp\n"
           "\n"
           "-- Set termios i_flag\n"
           "\n"
           "setInputFlag :: CTcflag -> TerminalAttributes -> TerminalAttributes\n"
           "setInputFlag flag termios = unsafePerformIO $ do\n"
           "  fp <- mallocForeignPtrBytes (", stdout);
#line 562 "Terminal.hsc"
    hsc_const (sizeof(struct termios));
    fputs (")\n"
           "", stdout);
    hsc_line (563, "Terminal.hsc");
    fputs ("  withForeignPtr fp $ \\p1 -> do\n"
           "    withTerminalAttributes termios $ \\p2 -> do\n"
           "      copyBytes p1 p2 (", stdout);
#line 565 "Terminal.hsc"
    hsc_const (sizeof(struct termios));
    fputs (") \n"
           "", stdout);
    hsc_line (566, "Terminal.hsc");
    fputs ("      iflag <- (", stdout);
#line 566 "Terminal.hsc"
    hsc_peek (struct termios, c_iflag);
    fputs (") p2\n"
           "", stdout);
    hsc_line (567, "Terminal.hsc");
    fputs ("      (", stdout);
#line 567 "Terminal.hsc"
    hsc_poke (struct termios, c_iflag);
    fputs (") p1 (iflag .|. flag)\n"
           "", stdout);
    hsc_line (568, "Terminal.hsc");
    fputs ("  return $ makeTerminalAttributes fp\n"
           "\n"
           "-- Examine termios i_flag\n"
           "\n"
           "testInputFlag :: CTcflag -> TerminalAttributes -> Bool\n"
           "testInputFlag flag termios = unsafePerformIO $\n"
           "  withTerminalAttributes termios $ \\p ->  do\n"
           "    iflag <- (", stdout);
#line 575 "Terminal.hsc"
    hsc_peek (struct termios, c_iflag);
    fputs (") p\n"
           "", stdout);
    hsc_line (576, "Terminal.hsc");
    fputs ("    return $! ((iflag .&. flag) /= 0)\n"
           "\n"
           "-- Clear termios c_flag\n"
           "\n"
           "clearControlFlag :: CTcflag -> TerminalAttributes -> TerminalAttributes\n"
           "clearControlFlag flag termios = unsafePerformIO $ do\n"
           "  fp <- mallocForeignPtrBytes (", stdout);
#line 582 "Terminal.hsc"
    hsc_const (sizeof(struct termios));
    fputs (")\n"
           "", stdout);
    hsc_line (583, "Terminal.hsc");
    fputs ("  withForeignPtr fp $ \\p1 -> do\n"
           "    withTerminalAttributes termios $ \\p2 -> do\n"
           "      copyBytes p1 p2 (", stdout);
#line 585 "Terminal.hsc"
    hsc_const (sizeof(struct termios));
    fputs (") \n"
           "", stdout);
    hsc_line (586, "Terminal.hsc");
    fputs ("      cflag <- (", stdout);
#line 586 "Terminal.hsc"
    hsc_peek (struct termios, c_cflag);
    fputs (") p2\n"
           "", stdout);
    hsc_line (587, "Terminal.hsc");
    fputs ("      (", stdout);
#line 587 "Terminal.hsc"
    hsc_poke (struct termios, c_cflag);
    fputs (") p1 (cflag .&. complement flag)\n"
           "", stdout);
    hsc_line (588, "Terminal.hsc");
    fputs ("  return $ makeTerminalAttributes fp\n"
           "\n"
           "-- Set termios c_flag\n"
           "\n"
           "setControlFlag :: CTcflag -> TerminalAttributes -> TerminalAttributes\n"
           "setControlFlag flag termios = unsafePerformIO $ do\n"
           "  fp <- mallocForeignPtrBytes (", stdout);
#line 594 "Terminal.hsc"
    hsc_const (sizeof(struct termios));
    fputs (")\n"
           "", stdout);
    hsc_line (595, "Terminal.hsc");
    fputs ("  withForeignPtr fp $ \\p1 -> do\n"
           "    withTerminalAttributes termios $ \\p2 -> do\n"
           "      copyBytes p1 p2 (", stdout);
#line 597 "Terminal.hsc"
    hsc_const (sizeof(struct termios));
    fputs (") \n"
           "", stdout);
    hsc_line (598, "Terminal.hsc");
    fputs ("      cflag <- (", stdout);
#line 598 "Terminal.hsc"
    hsc_peek (struct termios, c_cflag);
    fputs (") p2\n"
           "", stdout);
    hsc_line (599, "Terminal.hsc");
    fputs ("      (", stdout);
#line 599 "Terminal.hsc"
    hsc_poke (struct termios, c_cflag);
    fputs (") p1 (cflag .|. flag)\n"
           "", stdout);
    hsc_line (600, "Terminal.hsc");
    fputs ("  return $ makeTerminalAttributes fp\n"
           "\n"
           "-- Examine termios c_flag\n"
           "\n"
           "testControlFlag :: CTcflag -> TerminalAttributes -> Bool\n"
           "testControlFlag flag termios = unsafePerformIO $\n"
           "  withTerminalAttributes termios $ \\p -> do\n"
           "    cflag <- (", stdout);
#line 607 "Terminal.hsc"
    hsc_peek (struct termios, c_cflag);
    fputs (") p\n"
           "", stdout);
    hsc_line (608, "Terminal.hsc");
    fputs ("    return $! ((cflag .&. flag) /= 0)\n"
           "\n"
           "-- Clear termios l_flag\n"
           "\n"
           "clearLocalFlag :: CTcflag -> TerminalAttributes -> TerminalAttributes\n"
           "clearLocalFlag flag termios = unsafePerformIO $ do\n"
           "  fp <- mallocForeignPtrBytes (", stdout);
#line 614 "Terminal.hsc"
    hsc_const (sizeof(struct termios));
    fputs (")\n"
           "", stdout);
    hsc_line (615, "Terminal.hsc");
    fputs ("  withForeignPtr fp $ \\p1 -> do\n"
           "    withTerminalAttributes termios $ \\p2 -> do\n"
           "      copyBytes p1 p2 (", stdout);
#line 617 "Terminal.hsc"
    hsc_const (sizeof(struct termios));
    fputs (") \n"
           "", stdout);
    hsc_line (618, "Terminal.hsc");
    fputs ("      lflag <- (", stdout);
#line 618 "Terminal.hsc"
    hsc_peek (struct termios, c_lflag);
    fputs (") p2\n"
           "", stdout);
    hsc_line (619, "Terminal.hsc");
    fputs ("      (", stdout);
#line 619 "Terminal.hsc"
    hsc_poke (struct termios, c_lflag);
    fputs (") p1 (lflag .&. complement flag)\n"
           "", stdout);
    hsc_line (620, "Terminal.hsc");
    fputs ("  return $ makeTerminalAttributes fp\n"
           "\n"
           "-- Set termios l_flag\n"
           "\n"
           "setLocalFlag :: CTcflag -> TerminalAttributes -> TerminalAttributes\n"
           "setLocalFlag flag termios = unsafePerformIO $ do\n"
           "  fp <- mallocForeignPtrBytes (", stdout);
#line 626 "Terminal.hsc"
    hsc_const (sizeof(struct termios));
    fputs (")\n"
           "", stdout);
    hsc_line (627, "Terminal.hsc");
    fputs ("  withForeignPtr fp $ \\p1 -> do\n"
           "    withTerminalAttributes termios $ \\p2 -> do\n"
           "      copyBytes p1 p2 (", stdout);
#line 629 "Terminal.hsc"
    hsc_const (sizeof(struct termios));
    fputs (") \n"
           "", stdout);
    hsc_line (630, "Terminal.hsc");
    fputs ("      lflag <- (", stdout);
#line 630 "Terminal.hsc"
    hsc_peek (struct termios, c_lflag);
    fputs (") p2\n"
           "", stdout);
    hsc_line (631, "Terminal.hsc");
    fputs ("      (", stdout);
#line 631 "Terminal.hsc"
    hsc_poke (struct termios, c_lflag);
    fputs (") p1 (lflag .|. flag)\n"
           "", stdout);
    hsc_line (632, "Terminal.hsc");
    fputs ("  return $ makeTerminalAttributes fp\n"
           "\n"
           "-- Examine termios l_flag\n"
           "\n"
           "testLocalFlag :: CTcflag -> TerminalAttributes -> Bool\n"
           "testLocalFlag flag termios = unsafePerformIO $\n"
           "  withTerminalAttributes termios $ \\p ->  do\n"
           "    lflag <- (", stdout);
#line 639 "Terminal.hsc"
    hsc_peek (struct termios, c_lflag);
    fputs (") p\n"
           "", stdout);
    hsc_line (640, "Terminal.hsc");
    fputs ("    return $! ((lflag .&. flag) /= 0)\n"
           "\n"
           "-- Clear termios o_flag\n"
           "\n"
           "clearOutputFlag :: CTcflag -> TerminalAttributes -> TerminalAttributes\n"
           "clearOutputFlag flag termios = unsafePerformIO $ do\n"
           "  fp <- mallocForeignPtrBytes (", stdout);
#line 646 "Terminal.hsc"
    hsc_const (sizeof(struct termios));
    fputs (")\n"
           "", stdout);
    hsc_line (647, "Terminal.hsc");
    fputs ("  withForeignPtr fp $ \\p1 -> do\n"
           "    withTerminalAttributes termios $ \\p2 -> do\n"
           "      copyBytes p1 p2 (", stdout);
#line 649 "Terminal.hsc"
    hsc_const (sizeof(struct termios));
    fputs (") \n"
           "", stdout);
    hsc_line (650, "Terminal.hsc");
    fputs ("      oflag <- (", stdout);
#line 650 "Terminal.hsc"
    hsc_peek (struct termios, c_oflag);
    fputs (") p2\n"
           "", stdout);
    hsc_line (651, "Terminal.hsc");
    fputs ("      (", stdout);
#line 651 "Terminal.hsc"
    hsc_poke (struct termios, c_oflag);
    fputs (") p1 (oflag .&. complement flag)\n"
           "", stdout);
    hsc_line (652, "Terminal.hsc");
    fputs ("  return $ makeTerminalAttributes fp\n"
           "\n"
           "-- Set termios o_flag\n"
           "\n"
           "setOutputFlag :: CTcflag -> TerminalAttributes -> TerminalAttributes\n"
           "setOutputFlag flag termios = unsafePerformIO $ do\n"
           "  fp <- mallocForeignPtrBytes (", stdout);
#line 658 "Terminal.hsc"
    hsc_const (sizeof(struct termios));
    fputs (")\n"
           "", stdout);
    hsc_line (659, "Terminal.hsc");
    fputs ("  withForeignPtr fp $ \\p1 -> do\n"
           "    withTerminalAttributes termios $ \\p2 -> do\n"
           "      copyBytes p1 p2 (", stdout);
#line 661 "Terminal.hsc"
    hsc_const (sizeof(struct termios));
    fputs (") \n"
           "", stdout);
    hsc_line (662, "Terminal.hsc");
    fputs ("      oflag <- (", stdout);
#line 662 "Terminal.hsc"
    hsc_peek (struct termios, c_oflag);
    fputs (") p2\n"
           "", stdout);
    hsc_line (663, "Terminal.hsc");
    fputs ("      (", stdout);
#line 663 "Terminal.hsc"
    hsc_poke (struct termios, c_oflag);
    fputs (") p1 (oflag .|. flag)\n"
           "", stdout);
    hsc_line (664, "Terminal.hsc");
    fputs ("  return $ makeTerminalAttributes fp\n"
           "\n"
           "-- Examine termios o_flag\n"
           "\n"
           "testOutputFlag :: CTcflag -> TerminalAttributes -> Bool\n"
           "testOutputFlag flag termios = unsafePerformIO $\n"
           "  withTerminalAttributes termios $ \\p -> do\n"
           "    oflag <- (", stdout);
#line 671 "Terminal.hsc"
    hsc_peek (struct termios, c_oflag);
    fputs (") p\n"
           "", stdout);
    hsc_line (672, "Terminal.hsc");
    fputs ("    return $! ((oflag .&. flag) /= 0)\n"
           "\n"
           "withNewTermios :: TerminalAttributes -> (Ptr CTermios -> IO a) \n"
           "  -> IO TerminalAttributes\n"
           "withNewTermios termios action = do\n"
           "  fp1 <- mallocForeignPtrBytes (", stdout);
#line 677 "Terminal.hsc"
    hsc_const (sizeof(struct termios));
    fputs (")\n"
           "", stdout);
    hsc_line (678, "Terminal.hsc");
    fputs ("  withForeignPtr fp1 $ \\p1 -> do\n"
           "   withTerminalAttributes termios $ \\p2 -> do\n"
           "    copyBytes p1 p2 (", stdout);
#line 680 "Terminal.hsc"
    hsc_const (sizeof(struct termios));
    fputs (")\n"
           "", stdout);
    hsc_line (681, "Terminal.hsc");
    fputs ("    action p1\n"
           "  return $ makeTerminalAttributes fp1\n"
           "", stdout);
    return 0;
}
