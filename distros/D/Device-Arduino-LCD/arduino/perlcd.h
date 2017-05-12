#include <WProgram.h>
#include <LCD4Bit.h>
#include <string.h>


#define FALSE 0
#define TRUE  1

#define DEBUG 0
#define SERIAL_SPEED 9600

// command numbers.
#define ROW_ONE_TEXT 0x01
#define ROW_TWO_TEXT 0x02
#define SCROLL_UP    0x03
#define PLACE_STRING 0x04
#define SCROLL_LEFT  0x05
#define CLEAR        0x06
#define SET_GAUGE    0x07
#define MAKE_CHAR    0x08
#define SEND_CMD     0x09
#define PRINT        0x0A
#define WRITE_ASCII  0x0B

// reset the gauges and the display.
#define RESET        0x63

// screen defaults.
#define LINE_SIZE           16
#define LINES               2

// other screen variables.
#define DEFAULT_SCROLL_DELAY 150
#define BUFFER_SIZE         65
#define SPACE               0x20

// ddram addressing.
#define DDRAM_OFFSET        0x80
#define ROW_MULTIPLIER      0x40

// analog pins.
#define GAUGE_ONE         3
#define GAUGE_TWO         5
#define GAUGE_THREE       6
#define GAUGE_DEFAULT_VAL 0

// LED
#define LED 13


// max buffer sizes.
#define MAX_CMD_SIZE  3
#define MAX_DATA_SIZE 65

// message control.
#define HEADER_START 0x1A
#define DATA_START   0x1B
#define DATA_END     0x1C
#define STRING_TOK   0x1D

// function declarations.
void setup(void);
void loop(void);
int readIncoming(void);
void dispatchCommand(void);
void printDebugChar(char someChar);
void resetGauges(void);
void clearLineHistory();
void clearline(int lineNumber);
void clearOneLineHistory(int line);
void moveToChar(int row, int col);
int tokenizeData(char *tokenList[]);
void writeLine(int lineNumber, char *data);
void scrollRight(int num_chars, int delay_time);
void writeString(char *data);
void writeCharAt(int row, int col, char character);
void setGauge(void);
void recvCharData(void);
int defineCharacter(int ascii, int *data);
void logoScreen(void);
void blinkLED (int theDelay);
void writeAscii(char *data);
