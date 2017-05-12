void setup() {
  Serial.begin(9600);
  while(!Serial) {}
}

void loop() {
  int request_received = 0;
  
  while (Serial.available() > 0) {
    char a = Serial.read();
    request_received++;
  }

  delay(5000);
  if (request_received>0) {
    int response[] = { 3,3,6,2,0x2b,0,0,0,0x64, 0x26, 0x48};
    for (int i=0; i<11; i++) {
      Serial.write(response[i]);
    }
  }
}
