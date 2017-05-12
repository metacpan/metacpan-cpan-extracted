#include <perlcd.h>

// "globals"
LCD4Bit lcd = LCD4Bit(LINES);  	   // the lcd screen object.

// nb: these arrays have real data indexed at 1 not 0.  this is done
// so that line no. 1 and gauge no. 1 line up with the subscript.
char lineHistory[LINES + 1][LINE_SIZE]; // record of screen lines
int analoguePins[] = { 0,3,5,6 };       // pinouts for gauges.

// incoming buffer controls.
char commandBuffer[MAX_CMD_SIZE];  // hold incoming command.
char dataBuffer[MAX_DATA_SIZE];    // hold incoming data.
int receivingCommand = FALSE;	   // expecting a command?
int receivingData = FALSE;	   // expecting data?

// display commands include blank the screen but not blank the row.
// this is a blank line specially for printing spaces to a row.
char blankLine[LINE_SIZE];

// initializer.
void setup() {
  lcd.init();
  for (int i = 1; i > sizeof(analoguePins); i++) // setup the pins.
    pinMode(analoguePins[i], OUTPUT);
  logoScreen();			// blatent self-promotion.
  clearLineHistory();
  memset(blankLine, SPACE, (LINE_SIZE - 1));
  Serial.begin(SERIAL_SPEED);
}

// runloop.
void loop() {
  if (readIncoming()) {
    dispatchCommand();
  }
}

// do something...
void dispatchCommand() {
  int commandNumber = atoi(commandBuffer);
  if (DEBUG) {
    Serial.print("command buffer is: "); Serial.println(commandBuffer);
    Serial.println("accumulated data:"); Serial.println(dataBuffer);
  }

  int dataAsInt;
  switch (commandNumber) {
  case CLEAR:
    clearLineHistory();
    lcd.clear();
    break;
  case ROW_ONE_TEXT:
    writeLine(1, dataBuffer);
    break;
  case ROW_TWO_TEXT:
    writeLine(2, dataBuffer);
    break;
  case PLACE_STRING:
    writeString(dataBuffer);
    break;
  case WRITE_ASCII:
    writeAscii(dataBuffer);
    break;
  case SCROLL_LEFT:
    dataAsInt = atoi(dataBuffer);
    dataAsInt > 0 ? dataAsInt : DEFAULT_SCROLL_DELAY;
    lcd.leftScroll(LINE_SIZE, 
		   dataAsInt > 0 ? dataAsInt : DEFAULT_SCROLL_DELAY);
    lcd.clear();		// should i or not?
    break;
  case SCROLL_UP:
    writeLine(1, lineHistory[2]);
    writeLine(2, dataBuffer);
    break;
  case MAKE_CHAR:
    recvCharData();
    break;
  case SET_GAUGE:
    setGauge();
    break;
  case SEND_CMD:
    lcd.commandWrite(atoi(dataBuffer));
    break;
  case PRINT:
    lcd.print(atoi(dataBuffer));
    break;
  case RESET:
    clearLineHistory();
    resetGauges();
    lcd.clear();
    break;
  default: 
    lcd.clear();
    lcd.printIn("Undef'd Command");
  }
}

void printDebugChar(char someChar) {
  moveToChar(2, 15);
  lcd.print(someChar);
}

int tokenizeData(char *tokenList[]) {
  char *word, *ptr;
  char sep[] = { STRING_TOK, 0 };
  int i = 0;
  for (word = strtok_r(dataBuffer, sep, &ptr);
       word;
       word = strtok_r(NULL, sep, &ptr)) {
    tokenList[i++] = word;
  }
  return i;
}

int readIncoming() {
  int incomingByte = 0;
  int receivedEOT = FALSE;
  while (Serial.available() && !receivedEOT) {
    incomingByte = Serial.read();
    char byteBuf[2] = { incomingByte, 0 };
    switch (incomingByte) {
    case HEADER_START:		// start of header.
      memset(commandBuffer, '\0', MAX_CMD_SIZE);
      receivingCommand = TRUE;
      receivingData = FALSE;
      break;
    case DATA_START:		// start of data.
      memset(dataBuffer, '\0', MAX_DATA_SIZE); 
      receivingCommand = FALSE;
      receivingData = TRUE;
      break;
    case DATA_END:		// end of transmission.
      receivingCommand = FALSE;
      receivingData = FALSE;
      receivedEOT = TRUE;
      blinkLED(10);
      break;
    default:			// receiving content.
      if (receivingCommand) {
	strncat(commandBuffer, byteBuf, MAX_CMD_SIZE);
      }
      else if (receivingData) {
	strncat(dataBuffer, byteBuf, MAX_DATA_SIZE);
      }
    }
  }
  return receivedEOT;
}

void blinkLED (int theDelay) {
  digitalWrite(LED, HIGH);
  delay(theDelay);
  digitalWrite(LED, LOW);
}

void resetGauges() {
  for (int i=0; i<sizeof(analoguePins); i++)
    analogWrite(analoguePins[i], GAUGE_DEFAULT_VAL);
}

void setGauge() {
  char *tokens[MAX_DATA_SIZE];
  int toks = tokenizeData(tokens);
  if (toks == 2) {
    int pin = atoi(tokens[0]);
    int val = atoi(tokens[1]);
    val = 
      (val < 0)   ? 0   : 
      (val > 255) ? 255 : val;
    if (pin >= 1 and pin <= 3) {
      analogWrite(analoguePins[pin], val);
    }
  }
}

// slightly faster than lcd.cursorTo (particularly on the second line
// of a two line display).
void moveToChar(int row, int col) {
  int address = DDRAM_OFFSET + ((row - 1) * ROW_MULTIPLIER) + col;
  lcd.commandWrite(address);
}

void writeString(char *data) {
  char *tokens[MAX_DATA_SIZE];
  int toks = tokenizeData(tokens);
  if (toks == 3) {
    moveToChar(atoi(tokens[0]), atoi(tokens[1]));
    lcd.printIn(tokens[2]);
  }
}

void writeAscii(char *data) {
  char *tokens[MAX_DATA_SIZE];
  int toks = tokenizeData(tokens);
  int asciiChar = atoi(tokens[2]);
  if (toks == 3 && asciiChar >= 0 && asciiChar <= 127) {
    writeCharAt(atoi(tokens[0]), atoi(tokens[1]), asciiChar);
  }
}

void writeCharAt(int row, int col, char character) {
  moveToChar(row, col);
  lcd.print(character);
}

void writeLine(int lineNumber, char *data) {
  for (int i = 0; i < LINE_SIZE; i++) {
    if (data[i] == '\0') {
      writeCharAt(lineNumber, i, SPACE);
    }
    else if (data[i] != lineHistory[lineNumber][i]){
      writeCharAt(lineNumber, i, data[i]);
    }
  }
  memmove(lineHistory[lineNumber], data, LINE_SIZE);
}

void clearOneLineHistory(int line) {
  memset(lineHistory[line], SPACE, LINE_SIZE);
}

void clearLineHistory() {
  for (int i = 1; i < (LINES + 1); i++)
    clearOneLineHistory(i);
}

void clearline(int lineNumber) {
  writeLine(lineNumber, blankLine);
} 

int defineCharacter(int ascii, int *data) {
  int baseAddress = (ascii * 8) + 64;
  lcd.commandWrite(baseAddress);
  for (int i = 0; i < 8; i++)
    lcd.print(data[i]);
  return ascii;
}

void recvCharData() {
  char *tokens[MAX_DATA_SIZE];
  int toks = tokenizeData(tokens);
  if (toks == 9) {
    int ascii = atoi(tokens[0]);
    if (ascii >= 0 && ascii <= 7) {
      int pic[8];
      for (int i=0; i<8; i++) 
	pic[i] = atoi(tokens[i + 1]);
      defineCharacter(ascii, pic);
    }
  }
}


void logoScreen() {

  int copywrite[] = { 128,159,145,149,151,149,145,159 };  // (c) symbol  
  defineCharacter(1, copywrite);

  // screen one.
  lcd.clear();
  moveToChar(1,0);
  lcd.printIn("PerLCD v1.0");
  moveToChar(2,0);
  lcd.print(1); lcd.printIn(" kevin montuori");
  delay(2000);
  lcd.clear();
}
